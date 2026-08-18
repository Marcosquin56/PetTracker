import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Header de perfil (avatar + nombre). `onEditPhoto`/`onEditName` nulos =
/// perfil ajeno, sin lápiz de edición (ver PublicProfileScreen).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.displayName,
    required this.photoUrl,
    this.onEditPhoto,
    this.onEditName,
    super.key,
  });

  final String? displayName;
  final String? photoUrl;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = (displayName?.trim().isNotEmpty ?? false) ? displayName!.trim()[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: colorScheme.primaryContainer,
                foregroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
                child: Text(
                  initials,
                  style: TextStyle(fontSize: 32, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                ),
              ),
              if (onEditPhoto != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primary,
                      child: Icon(Icons.edit, size: 14, color: colorScheme.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onEditName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName?.trim().isNotEmpty ?? false ? displayName! : 'Sin nombre',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (onEditName != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
