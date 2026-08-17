import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../models/chat_message_model.dart';

/// Wrapper sobre `socket_io_client`: conecta al namespace `/chat` del
/// backend (JWT en el handshake, mismo mecanismo que valida `ChatGateway`
/// del lado del servidor) y expone los mensajes entrantes como stream.
class ChatSocketService {
  socket_io.Socket? _socket;
  final _messages = StreamController<ChatMessageModel>.broadcast();

  Stream<ChatMessageModel> get messages => _messages.stream;

  void connect({required String baseUrl, required String token}) {
    if (_socket != null) return;

    _socket = socket_io.io(
      '$baseUrl/chat',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('newMessage', (data) {
      _messages.add(ChatMessageModel.fromJson(Map<String, dynamic>.from(data as Map)));
    });

    _socket!.connect();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('joinConversation', {'conversationId': conversationId});
  }

  void sendMessage(String conversationId, String content) {
    _socket?.emit('sendMessage', {'conversationId': conversationId, 'content': content});
  }

  void dispose() {
    _socket?.dispose();
    _messages.close();
  }
}
