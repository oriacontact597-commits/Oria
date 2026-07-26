import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Search bar pill, sticky, style Notion.
/// Utilisée dans Explorer, Diagnostic, etc.
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hintText = 'Rechercher…',
    this.onChanged,
    this.onMicTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (onMicTap != null)
            GestureDetector(
              onTap: onMicTap,
              child: const Icon(Icons.mic_none,
                  color: AppColors.textLight, size: 20),
            ),
        ],
      ),
    );
  }
}
