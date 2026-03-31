import 'package:coinly/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.showBackButton = true,
  });

  final String title;
  final bool centerTitle;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: centerTitle,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Back',
            )
          : const SizedBox.shrink(),
      actions: [SizedBox(width: showBackButton ? 48 : 16)],
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
