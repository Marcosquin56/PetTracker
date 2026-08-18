import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/profile_providers.dart';

/// Buscador de personas (`/search`) — con debounce simple para no pegarle
/// al backend en cada tecla.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre…',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _query.trim().length < 2
          ? const Center(child: Text('Escribí al menos 2 letras para buscar.'))
          : resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return const Center(child: Text('No encontramos a nadie con ese nombre.'));
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        foregroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
                        child: Text((user.displayName?.trim().isNotEmpty ?? false) ? user.displayName![0] : '?'),
                      ),
                      title: Text(user.displayName ?? 'Sin nombre'),
                      onTap: () => context.push('/profile/${user.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('No se pudo buscar.\n$error')),
            ),
    );
  }
}
