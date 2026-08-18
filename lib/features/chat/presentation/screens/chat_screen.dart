import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/auth_controller.dart';
import '../../application/chat_providers.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  bool _isSendingAttachment = false;
  bool _isRecording = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(chatControllerProvider(widget.conversationId).notifier).send(text);
    _textController.clear();
    setState(() {});
  }

  Future<void> _sendAttachment({
    required String filePath,
    required String fileName,
    required String type,
    int? durationMs,
  }) async {
    setState(() => _isSendingAttachment = true);
    try {
      await ref.read(chatControllerProvider(widget.conversationId).notifier).sendAttachment(
            filePath: filePath,
            fileName: fileName,
            type: type,
            durationMs: durationMs,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar el adjunto.\n$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingAttachment = false);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final photo = await _imagePicker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (photo == null) return;
    await _sendAttachment(filePath: photo.path, fileName: photo.name, type: 'image');
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;
    await _sendAttachment(filePath: path, fileName: result!.files.single.name, type: 'file');
  }

  Future<void> _showAttachmentSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.of(sheetContext).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Archivo'),
              onTap: () => Navigator.of(sheetContext).pop('file'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'camera':
        await _pickAndSendImage(ImageSource.camera);
      case 'gallery':
        await _pickAndSendImage(ImageSource.gallery);
      case 'file':
        await _pickAndSendFile();
    }
  }

  Future<void> _startRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);
    if (!await recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Necesitamos permiso de micrófono para grabar audio.')),
        );
      }
      return;
    }
    await recorder.start();
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingElapsed = Duration.zero;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingElapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecordingAndSend() async {
    _recordingTimer?.cancel();
    final recorded = await ref.read(audioRecorderServiceProvider).stop();
    if (mounted) setState(() => _isRecording = false);
    if (recorded == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo grabar el audio. Probá de nuevo.')),
        );
      }
      return;
    }
    await _sendAttachment(
      filePath: recorded.path,
      fileName: 'audio.m4a',
      type: 'audio',
      durationMs: recorded.durationMs,
    );
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await ref.read(audioRecorderServiceProvider).cancel();
    if (mounted) setState(() => _isRecording = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = chatControllerProvider(widget.conversationId);
    final state = ref.watch(provider);
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    // `watch` (no `read`) es clave: audioRecorderServiceProvider es
    // autoDispose, así que sin un listener activo Riverpod lo destruye y
    // recrea entre que se arranca a grabar y se toca "enviar" — el
    // grabador "nuevo" nunca arrancó nada, `.stop()` devuelve null y el
    // audio se pierde en silencio. Mismo patrón que chatSocketService más
    // abajo en chat_providers.dart.
    ref.watch(audioRecorderServiceProvider);

    ref.listen(provider, (previous, next) {
      if (next.messages.length != (previous?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? Center(
                        child: Text(
                          'Todavía no hay mensajes.\n¡Escribí el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final isMine = message.senderId == currentUserId;
                          return _MessageBubble(message: message, isMine: isMine);
                        },
                      ),
          ),
          if (_isSendingAttachment) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _isRecording ? _buildRecordingRow(colorScheme) : _buildInputRow(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ColorScheme colorScheme) {
    final hasText = _textController.text.trim().isNotEmpty;
    return Row(
      children: [
        IconButton(
          onPressed: _isSendingAttachment ? null : _showAttachmentSheet,
          icon: const Icon(Icons.add_circle_outline),
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(hintText: 'Escribí un mensaje...'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: hasText ? _send : _startRecording,
          icon: Icon(hasText ? Icons.send : Icons.mic),
        ),
      ],
    );
  }

  Widget _buildRecordingRow(ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          onPressed: _cancelRecording,
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
        ),
        Expanded(
          child: Row(
            children: [
              Icon(Icons.fiber_manual_record, color: colorScheme.error, size: 14),
              const SizedBox(width: 8),
              Text('Grabando ${_formatDuration(_recordingElapsed)}'),
            ],
          ),
        ),
        IconButton.filled(onPressed: _stopRecordingAndSend, icon: const Icon(Icons.send)),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessageEntity message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isMine ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final isImage = message.type == ChatMessageType.image;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: isImage ? 6 : 14, vertical: isImage ? 6 : 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(textColor),
            if (message.content.isNotEmpty && message.type != ChatMessageType.text)
              Padding(
                padding: EdgeInsets.fromLTRB(isImage ? 8 : 0, 6, isImage ? 8 : 0, 0),
                child: Text(message.content, style: TextStyle(color: textColor)),
              ),
            const SizedBox(height: 2),
            Text(
              DateFormat.Hm().format(message.createdAt.toLocal()),
              style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    switch (message.type) {
      case ChatMessageType.text:
        return Text(message.content, style: TextStyle(color: textColor));
      case ChatMessageType.image:
        return _ImageAttachment(url: message.attachmentUrl!);
      case ChatMessageType.audio:
        return _AudioAttachment(url: message.attachmentUrl!, durationMs: message.attachmentDurationMs ?? 0, color: textColor);
      case ChatMessageType.file:
        return _FileAttachment(url: message.attachmentUrl!, name: message.attachmentName ?? 'Archivo', color: textColor);
    }
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
              SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator())),
          errorWidget: (_, __, ___) =>
              const SizedBox(width: 220, height: 220, child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}

class _AudioAttachment extends StatefulWidget {
  const _AudioAttachment({required this.url, required this.durationMs, required this.color});

  final String url;
  final int durationMs;
  final Color color;

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  final _player = AudioPlayer();
  bool _isLoaded = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (!_isLoaded) {
      await _player.setUrl(widget.url);
      _isLoaded = true;
    }
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final total = Duration(milliseconds: widget.durationMs);

    return SizedBox(
      width: 180,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final processingState = snapshot.data?.processingState;
              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                return SizedBox(
                  width: 32,
                  height: 32,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(strokeWidth: 2, color: widget.color),
                  ),
                );
              }
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                onPressed: _togglePlay,
                icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: widget.color, size: 32),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final progress = total.inMilliseconds == 0 ? 0.0 : position.inMilliseconds / total.inMilliseconds;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      color: widget.color,
                      backgroundColor: widget.color.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(position > Duration.zero ? position : total),
                      style: TextStyle(fontSize: 11, color: widget.color),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.url, required this.name, required this.color});

  final String url;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(color: color, decoration: TextDecoration.underline),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
