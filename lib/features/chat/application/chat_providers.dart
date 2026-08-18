import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/datasources/chat_remote_datasource.dart';
import '../data/datasources/chat_socket_service.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/entities/chat_message_entity.dart';
import '../domain/repositories/chat_repository.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});

/// Lista de conversaciones para el inbox. `autoDispose` + `family`-less:
/// se recarga cada vez que se vuelve a entrar a la pantalla del inbox.
final conversationsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(chatRepositoryProvider).getConversations();
});

/// Total de mensajes no leídos entre todas las conversaciones, para el
/// puntito de la pestaña "Chats" de la barra inferior. `0` mientras carga o
/// si falla — el detalle real ya se ve dentro del inbox.
final unreadChatsCountProvider = Provider.autoDispose((ref) {
  return ref.watch(conversationsProvider).valueOrNull?.fold<int>(
        0,
        (total, conversation) => total + conversation.unreadCount,
      ) ??
      0;
});

/// Una conexión de socket por pantalla de chat abierta — se cierra sola al
/// salir de la pantalla (autoDispose).
final chatSocketServiceProvider = Provider.autoDispose<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(service.dispose);
  return service;
});

class ChatState {
  const ChatState({this.messages = const [], this.isLoading = true, this.error});

  /// Orden ascendente (más viejo primero), listo para pintar de arriba a abajo.
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final Object? error;

  ChatState copyWith({List<ChatMessageEntity>? messages, bool? isLoading, Object? error}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final chatControllerProvider =
    AutoDisposeNotifierProviderFamily<ChatController, ChatState, String>(ChatController.new);

class ChatController extends AutoDisposeFamilyNotifier<ChatState, String> {
  late final String _conversationId;
  StreamSubscription<ChatMessageModel>? _subscription;

  @override
  ChatState build(String conversationId) {
    _conversationId = conversationId;
    // `watch` (no `read`) es clave: chatSocketServiceProvider es autoDispose,
    // así que necesita al menos un listener activo o Riverpod lo destruye
    // (cerrando el socket a mitad del handshake) apenas termina este build.
    final socket = ref.watch(chatSocketServiceProvider);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_init(conversationId, socket));
    return const ChatState();
  }

  Future<void> _init(String conversationId, ChatSocketService socket) async {
    try {
      final history = await ref.read(chatRepositoryProvider).getMessages(conversationId);
      state = state.copyWith(messages: history.reversed.toList(), isLoading: false);
      unawaited(_markAsRead(conversationId));
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }

    final apiClient = ref.read(apiClientProvider);
    final token = await apiClient.readAccessToken();
    if (token == null) return;

    socket.connect(baseUrl: apiClient.baseUrl, token: token);
    socket.joinConversation(conversationId);

    _subscription = socket.messages.listen((message) {
      if (message.conversationId != conversationId) return;
      state = state.copyWith(messages: [...state.messages, message]);
    });
  }

  void send(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    ref.read(chatSocketServiceProvider).sendMessage(_conversationId, trimmed);
  }

  /// No crítico si falla: el contador de no-leídos queda desactualizado
  /// hasta que se vuelva a abrir el inbox o llegue un mensaje nuevo.
  Future<void> _markAsRead(String conversationId) async {
    try {
      await ref.read(chatRepositoryProvider).markAsRead(conversationId);
      ref.invalidate(conversationsProvider);
    } catch (_) {}
  }
}
