// Genera el ícono de la app (huella + lupa) dibujando en un Canvas, sin
// depender de ningún asset externo. Correr con:
//   flutter test tool/generate_app_icon.dart
// Produce:
//   assets/icon/app_icon.png             (fondo + glifo, para el ícono legacy)
//   assets/icon/app_icon_foreground.png  (glifo solo, fondo transparente,
//                                          escalado para el "safe zone" del
//                                          adaptive icon de Android)
// Después: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _canvasSize = 1024.0;
const _background = Color(0xFFE8703F);

void main() {
  test('generate app icon', () async {
    await _renderTo('assets/icon/app_icon.png', withBackground: true);
    await _renderTo('assets/icon/app_icon_foreground.png', withBackground: false);
  });
}

Future<void> _renderTo(String path, {required bool withBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (withBackground) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, _canvasSize, _canvasSize), Paint()..color = _background);
    _drawGlyph(canvas);
  } else {
    // El glifo del adaptive icon debe caber en el "safe zone" (~66% central)
    // para no recortarse con la animación/máscara del launcher.
    canvas.save();
    canvas.translate(_canvasSize / 2, _canvasSize / 2);
    canvas.scale(0.68);
    canvas.translate(-_canvasSize / 2, -_canvasSize / 2);
    _drawGlyph(canvas);
    canvas.restore();
  }

  final image = await recorder.endRecording().toImage(_canvasSize.toInt(), _canvasSize.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
}

/// Huella (pad principal + 4 dedos) con una lupa "enfocándola" — el mango
/// sale hacia abajo a la derecha.
void _drawGlyph(Canvas canvas) {
  final white = Paint()..color = Colors.white;

  canvas.drawOval(Rect.fromCenter(center: const Offset(430, 590), width: 300, height: 250), white);

  void toe(Offset center, double w, double h) {
    canvas.drawOval(Rect.fromCenter(center: center, width: w, height: h), white);
  }

  toe(const Offset(300, 400), 130, 160);
  toe(const Offset(400, 325), 130, 170);
  toe(const Offset(510, 325), 130, 170);
  toe(const Offset(600, 400), 120, 150);

  const lensCenter = Offset(660, 640);
  const lensRadius = 190.0;
  canvas.drawCircle(
    lensCenter,
    lensRadius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 46
      ..strokeCap = StrokeCap.round,
  );

  const direction = Offset(0.72, 0.72);
  final handleStart = lensCenter + direction * lensRadius;
  final handleEnd = handleStart + direction * 220;
  canvas.drawLine(
    handleStart,
    handleEnd,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 52
      ..strokeCap = StrokeCap.round,
  );
}
