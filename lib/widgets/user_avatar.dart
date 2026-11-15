import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/text_utils.dart';

String? resolveAvatarUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http')) return value;
  return Supabase.instance.client.storage
      .from(Buckets.avatars)
      .getPublicUrl(value);
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.url,
    this.name,
    this.radius = 20,
    this.color = kPrimary,
    this.image,
  });

  final String? url;
  final String? name;
  final double radius;
  final Color color;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAvatarUrl(url);
    final provider = image ??
        (resolved != null ? CachedNetworkImageProvider(resolved) : null);

    return CircleAvatar(
      radius: radius,
      backgroundColor: kSurfaceAlt,
      backgroundImage: provider,
      onBackgroundImageError: provider == null ? null : (_, _) {},
      child: provider == null
          ? Text(
              initialOf(name),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.75,
              ),
            )
          : null,
    );
  }
}

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kPrimary.withValues(alpha: 0.12),
      child: Icon(Icons.group, color: kPrimary, size: radius),
    );
  }
}
