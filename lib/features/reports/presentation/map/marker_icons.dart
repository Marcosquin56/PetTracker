import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Genera los íconos de los markers del mapa dibujando en un [Canvas]:
/// un "avatar" circular (foto de la mascota o emoji de respaldo) con borde
/// de color por estado y una colita apuntando al punto — al estilo
/// Life360 — para los reportes individuales, y un círculo con contador
/// para los clusters.
class MarkerIcons {
  const MarkerIcons._();

  /// Cachea por id + foto + color: generar el bitmap implica decodificar
  /// una imagen de red, no querés repetirlo en cada rebuild de markers.
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> avatar({
    required String cacheKey,
    required Color color,
    required String fallbackEmoji,
    String? photoUrl,
    double size = 100,
  }) async {
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    ui.Image? photo;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        photo = await _loadNetworkImage(photoUrl).timeout(const Duration(seconds: 5));
      } catch (_) {
        photo = null;
      }
    }

    final descriptor = await _renderAvatar(
      size: size,
      color: color,
      fallbackEmoji: fallbackEmoji,
      photo: photo,
    );
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> count(int count, Color color, {double baseSize = 46}) {
    final size = baseSize + count.clamp(1, 30) * 1.4;
    return _renderCountBubble(size: size, color: color, text: '$count');
  }

  static Future<ui.Image> _loadNetworkImage(String url) {
    final completer = Completer<ui.Image>();
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Future<BitmapDescriptor> _renderAvatar({
    required double size,
    required Color color,
    required String fallbackEmoji,
    ui.Image? photo,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const tailHeight = 14.0;
    final circleRadius = (size - tailHeight) / 2 - 4;
    final center = Offset(size / 2, circleRadius + 4);

    // Sombra sutil.
    canvas.drawCircle(
      center.translate(0, 2),
      circleRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Anillo de color por estado + borde blanco.
    canvas.drawCircle(center, circleRadius, Paint()..color = color);
    canvas.drawCircle(center, circleRadius - 4, Paint()..color = Colors.white);

    final innerRadius = circleRadius - 7;
    final clipRect = Rect.fromCircle(center: center, radius: innerRadius);

    canvas.save();
    canvas.clipPath(Path()..addOval(clipRect));

    if (photo != null) {
      final srcSize = Size(photo.width.toDouble(), photo.height.toDouble());
      final srcRect = _coverRect(srcSize, clipRect.size);
      canvas.drawImageRect(photo, srcRect, clipRect, Paint()..filterQuality = FilterQuality.medium);
    } else {
      canvas.drawOval(clipRect, Paint()..color = color.withValues(alpha: 0.15));
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(text: fallbackEmoji, style: TextStyle(fontSize: innerRadius * 1.1))
        ..layout();
      painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
    }
    canvas.restore();

    // Colita apuntando al punto exacto de la ubicación.
    final tailTop = center.dy + circleRadius - 2;
    final tailPath = Path()
      ..moveTo(center.dx - 9, tailTop)
      ..lineTo(center.dx + 9, tailTop)
      ..lineTo(center.dx, tailTop + tailHeight)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = color);

    final image = await recorder.endRecording().toImage(size.round(), size.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _renderCountBubble({
    required double size,
    required Color color,
    required String text,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = size / 2;

    canvas.drawCircle(Offset(radius, radius), radius, Paint()..color = color);
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: Colors.white, fontSize: size / 2.6, fontWeight: FontWeight.w800),
      )
      ..layout();
    painter.paint(canvas, Offset(radius - painter.width / 2, radius - painter.height / 2));

    final image = await recorder.endRecording().toImage(size.round(), size.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Recorte tipo `BoxFit.cover`: la porción de [source] que llena [target]
  /// sin deformar la imagen.
  static Rect _coverRect(Size source, Size target) {
    final srcAspect = source.width / source.height;
    final dstAspect = target.width / target.height;

    if (srcAspect > dstAspect) {
      final newWidth = source.height * dstAspect;
      final dx = (source.width - newWidth) / 2;
      return Rect.fromLTWH(dx, 0, newWidth, source.height);
    }

    final newHeight = source.width / dstAspect;
    final dy = (source.height - newHeight) / 2;
    return Rect.fromLTWH(0, dy, source.width, newHeight);
  }
}
