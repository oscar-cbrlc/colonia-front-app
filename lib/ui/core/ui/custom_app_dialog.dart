import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

Future<T?> showCustomAppDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? contentWidget,
  required IconData icon,
  Color primaryColor = AppTheme.primaryColor,
  String? confirmLabel,
  String? cancelLabel,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CustomAppDialog(
        title: title,
        message: message,
        contentWidget: contentWidget,
        icon: icon,
        primaryColor: primaryColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final heightFactor = Tween<double>(begin: 0.001, end: 1.0).animate(curvedAnimation);

      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, innerChild) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, heightFactor.value, 1.0),
            child: FadeTransition(
              opacity: animation,
              child: innerChild,
            ),
          );
        },
        child: child,
      );
    },
  );
}

class CustomAppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? contentWidget;
  final IconData icon;
  final Color primaryColor;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CustomAppDialog({
    super.key,
    required this.title,
    this.message,
    this.contentWidget,
    required this.icon,
    this.primaryColor = AppTheme.primaryColor,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          color: AppTheme.darkBackground.withAlpha(245),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.0,
                      fontFamily: 'Oswald',
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cancelLabel != null || confirmLabel == null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop(false);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),
            if (message != null)
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
            if (contentWidget != null) contentWidget!,
            if (cancelLabel != null || confirmLabel != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (cancelLabel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white38, width: 1),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (onCancel != null) {
                            onCancel!();
                          } else {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: Text(
                          cancelLabel!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (confirmLabel != null) const SizedBox(width: 12),
                  ],
                  if (confirmLabel != null)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primaryColor,
                          foregroundColor: AppTheme.darkBackground,
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (onConfirm != null) {
                            onConfirm!();
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: Text(
                          confirmLabel!.toUpperCase(),
                          style: TextStyle(
                            color: (primaryColor == Colors.redAccent || primaryColor == AppTheme.errorColor) 
                                ? Colors.white 
                                : AppTheme.darkBackground,
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
