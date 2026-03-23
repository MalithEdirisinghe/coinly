import 'dart:async';

import 'package:coinly/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppToastType { success, error }

abstract final class AppToast {
  static OverlayEntry? _currentEntry;
  static GlobalKey<_ToastMessageState>? _toastKey;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.success,
  }) {
    _removeCurrent(immediate: true);

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    final palette = _ToastPalette.fromType(type);
    final key = GlobalKey<_ToastMessageState>();
    _toastKey = key;

    _currentEntry = OverlayEntry(
      builder: (context) {
        return _ToastMessage(
          key: key,
          message: message,
          backgroundColor: palette.backgroundColor,
          foregroundColor: palette.foregroundColor,
          borderColor: palette.borderColor,
          icon: palette.icon,
          onHidden: () {
            if (identical(_toastKey, key)) {
              _removeCurrent(immediate: true);
            }
          },
        );
      },
    );

    overlay.insert(_currentEntry!);
  }

  static void dismiss() {
    _toastKey?.currentState?.dismiss();
  }

  static void _removeCurrent({required bool immediate}) {
    if (!immediate) {
      _toastKey?.currentState?.dismiss();
      return;
    }

    _currentEntry?.remove();
    _currentEntry = null;
    _toastKey = null;
  }
}

class _ToastMessage extends StatefulWidget {
  const _ToastMessage({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    required this.onHidden,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData icon;
  final VoidCallback onHidden;

  @override
  State<_ToastMessage> createState() => _ToastMessageState();
}

class _ToastMessageState extends State<_ToastMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _offset = Tween<Offset>(begin: const Offset(0, -0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 3), dismiss);
  }

  Future<void> dismiss() async {
    if (_isDismissing) {
      return;
    }
    _isDismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) {
      widget.onHidden();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _offset,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: widget.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: widget.foregroundColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.foregroundColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastPalette {
  const _ToastPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData icon;

  factory _ToastPalette.fromType(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastPalette(
          backgroundColor: Color(0xFFEAF8F2),
          foregroundColor: AppColors.accentDark,
          borderColor: Color(0xFFBEE9D3),
          icon: Icons.check_rounded,
        );
      case AppToastType.error:
        return const _ToastPalette(
          backgroundColor: Color(0xFFFDEEEE),
          foregroundColor: AppColors.error,
          borderColor: Color(0xFFF6CACA),
          icon: Icons.error_outline_rounded,
        );
    }
  }
}
