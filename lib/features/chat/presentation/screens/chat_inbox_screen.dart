import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/chat_providers.dart';
import '../../domain/entities/conversation_summary_entity.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: conversations.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyInbox();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _ConversationTile(conversation: items[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No se pudieron cargar los chats.\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(conversationsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'Todavía no tenés chats.\nEscribile al dueño de un reporte para arrancar uno.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final ConversationSummaryEntity conversation;

  @override
  Widget build(BuildContext context) {
    final title = conversation.otherUserDisplayName ?? 'Usuario';
    final subtitleParts = [
      if (conversation.petName != null) conversation.petName!,
      if (conversation.lastMessageContent != null) conversation.lastMessageContent!,
    ];
    final subtitle = subtitleParts.isEmpty ? 'Sin mensajes todavía' : subtitleParts.join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            conversation.otherUserPhotoUrl != null ? NetworkImage(conversation.otherUserPhotoUrl!) : null,
        child: conversation.otherUserPhotoUrl == null ? const Icon(Icons.person_outline) : null,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        _formatTimestamp(conversation.lastMessageAt ?? conversation.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    return isToday ? DateFormat.Hm().format(local) : DateFormat('d/M').format(local);
  }
}
