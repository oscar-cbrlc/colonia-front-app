import 'package:flutter/material.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/custom_app_dialog.dart';

Future<void> showSharedDownloadModelsDialog({
  required BuildContext context,
  required Listenable listenable,
  required double Function() getProgress,
  required bool Function() getIsDownloading,
  required VoidCallback onStartDownload,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _SharedDownloadModelsDialog(
        listenable: listenable,
        getProgress: getProgress,
        getIsDownloading: getIsDownloading,
        onStartDownload: onStartDownload,
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

class _SharedDownloadModelsDialog extends StatefulWidget {
  final Listenable listenable;
  final double Function() getProgress;
  final bool Function() getIsDownloading;
  final VoidCallback onStartDownload;

  const _SharedDownloadModelsDialog({
    required this.listenable,
    required this.getProgress,
    required this.getIsDownloading,
    required this.onStartDownload,
  });

  @override
  State<_SharedDownloadModelsDialog> createState() => _SharedDownloadModelsDialogState();
}

class _SharedDownloadModelsDialogState extends State<_SharedDownloadModelsDialog> {
  bool _isDownloading = false;
  bool _hasPopped = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = AppTheme.primaryColor;

    return ListenableBuilder(
      listenable: widget.listenable,
      builder: (context, _) {
        final progress = widget.getProgress();
        final isDownloading = widget.getIsDownloading();
        
        if (progress >= 1.0 && _isDownloading && !isDownloading && !_hasPopped) {
          _hasPopped = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return PopScope(
          canPop: !_isDownloading,
          child: CustomAppDialog(
            title: _isDownloading ? locale.downloadingModelsTitle : locale.downloadModelsTitle,
            message: _isDownloading ? null : locale.downloadModelsMessage,
            icon: Icons.cloud_download,
            primaryColor: AppTheme.primaryColor,
            cancelLabel: _isDownloading ? null : locale.cancel,
            confirmLabel: _isDownloading ? null : locale.download,
            onConfirm: () {
              setState(() => _isDownloading = true);
              widget.onStartDownload();
            },
            contentWidget: _isDownloading 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale.downloadModelsProgress((progress * 100).toInt().toString()),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}
