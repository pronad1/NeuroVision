// lib/src/ui/widgets/nv_top_bar.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NVTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String user;
  final Color roleColor;

  const NVTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.user,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: NVColors.bgSurface,
        border: Border(bottom: BorderSide(color: NVColors.border)),
      ),
      child: Row(
        children: [
          // Title block — Expanded so it doesn't push right-side items off
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: NVColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: NVColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Text(
              user.isNotEmpty ? user[0].toUpperCase() : 'U',
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              user,
              style: const TextStyle(
                color: NVColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
