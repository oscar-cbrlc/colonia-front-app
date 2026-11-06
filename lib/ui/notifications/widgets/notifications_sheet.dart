import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/data/repositories/notification_repository.dart';
import 'package:colonia_front_app/domain/models/notification.dart' as domain;
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const NotificationsSheet(),
  );
}

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationRepository>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final repository = context.watch<NotificationRepository>();
    final globalNotifications = repository.globalNotifications;
    final personalNotifications = repository.personalNotifications;
    final isLoading = repository.isLoading;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: const ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground,
      ),
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_sharp,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        locale.notificationsTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oswald',
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicator: ShapeDecoration(
                  color: AppTheme.secondaryColor.withAlpha(25),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.secondaryColor.withAlpha(120),
                      width: 1,
                    ),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
                tabs: [
                  Tab(text: locale.globalNotifications.toUpperCase()),
                  Tab(text: locale.personalNotifications.toUpperCase()),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  children: [
                    _NotificationList(
                      notifications: globalNotifications,
                      isLoading: isLoading,
                      emptyMessage: locale.noGlobalNotifications,
                      isPersonal: false,
                    ),
                    _NotificationList(
                      notifications: personalNotifications,
                      isLoading: isLoading,
                      emptyMessage: locale.noPersonalNotifications,
                      isPersonal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends StatefulWidget {
  final List<domain.Notification> notifications;
  final bool isLoading;
  final String emptyMessage;
  final bool isPersonal;

  const _NotificationList({
    required this.notifications,
    required this.isLoading,
    required this.emptyMessage,
    required this.isPersonal,
  });

  @override
  State<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<_NotificationList> {
  int? _expandedDeleteId;

  void _collapseDelete() {
    if (_expandedDeleteId != null) {
      setState(() {
        _expandedDeleteId = null;
      });
    }
  }

  void _toggleDeleteExpand(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedDeleteId == id) {
        _expandedDeleteId = null;
      } else {
        _expandedDeleteId = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (widget.notifications.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return GestureDetector(
      onTap: _collapseDelete,
      behavior: HitTestBehavior.opaque,
      child: RefreshIndicator(
        onRefresh: () async {
          _collapseDelete();
          await context.read<NotificationRepository>().fetchNotifications();
        },
        color: AppTheme.primaryColor,
        child: ListView.builder(
          itemCount: widget.notifications.length,
          padding: const EdgeInsets.only(bottom: 16),
          itemBuilder: (context, index) {
            final notification = widget.notifications[index];
            return _NotificationCard(
              notification: notification,
              isPersonal: widget.isPersonal,
              isDeleteExpanded: _expandedDeleteId == notification.id,
              onToggleDeleteExpand: () => _toggleDeleteExpand(notification.id),
              onCardTap: _collapseDelete,
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final domain.Notification notification;
  final bool isPersonal;
  final bool isDeleteExpanded;
  final VoidCallback onToggleDeleteExpand;
  final VoidCallback onCardTap;

  const _NotificationCard({
    required this.notification,
    required this.isPersonal,
    required this.isDeleteExpanded,
    required this.onToggleDeleteExpand,
    required this.onCardTap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isDeleting = false;

  String _formatDate(String dateStr) {
    final dateTime = DateTime.tryParse(dateStr)?.toLocal();
    if (dateTime == null) return dateStr;
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'join_team_request_accepted':
        return Icons.group_add;
      case 'join_team_request_denied':
        return Icons.person_remove_outlined;
      case 'team_kick':
        return Icons.no_accounts_outlined;
      case 'global':
        return Icons.public;
      default:
        return Icons.notifications_sharp;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'join_team_request_accepted':
        return AppTheme.successColor;
      case 'join_team_request_denied':
      case 'team_kick':
        return AppTheme.secondaryColor;
      case 'global':
        return AppTheme.primaryColor;
      default:
        return AppTheme.tertiaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final notification = widget.notification;
    final typeStr = notification.type;
    final iconData = _getIconForType(typeStr);
    final iconColor = _getIconColor(typeStr);

    final messageParts = notification.getMessageParts(locale);

    return GestureDetector(
      onTap: widget.onCardTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.white.withAlpha(10),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: widget.isPersonal
                  ? AppTheme.tertiaryColor.withAlpha(100)
                  : AppTheme.primaryColor.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: ShapeDecoration(
                    color: iconColor.withAlpha(25),
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: iconColor.withAlpha(120), width: 1),
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oswald',
                            fontSize: 14,
                          ),
                          children: [
                            if (messageParts['before'] != null && messageParts['before']!.isNotEmpty)
                              TextSpan(text: messageParts['before']),
                            if (messageParts['value'] != null && messageParts['value']!.isNotEmpty)
                              TextSpan(
                                text: messageParts['value'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            if (messageParts['after'] != null && messageParts['after']!.isNotEmpty)
                              TextSpan(text: messageParts['after']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notification.date),
                        style: TextStyle(
                          color: AppTheme.primaryColor.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.isPersonal) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.secondaryColor,
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          if (!widget.isDeleteExpanded) {
                            widget.onToggleDeleteExpand();
                          } else {
                            setState(() {
                              _isDeleting = true;
                            });
                            final messenger = ScaffoldMessenger.of(context);
                            final repository = context.read<NotificationRepository>();
                            final success = await repository.deleteNotification(notification.id);
                            if (!mounted) return;
                            if (!success) {
                              setState(() {
                                _isDeleting = false;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(locale.deleteNotification),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubicEmphasized,
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isDeleteExpanded ? 10 : 8,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: widget.isDeleteExpanded
                                ? AppTheme.secondaryColor.withAlpha(50)
                                : AppTheme.secondaryColor.withAlpha(25),
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                widget.isDeleteExpanded ? 8 : 6,
                              ),
                              side: BorderSide(
                                color: widget.isDeleteExpanded
                                    ? Colors.white70
                                    : AppTheme.secondaryColor.withAlpha(120),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: AppTheme.secondaryColor,
                                size: 18,
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOutCubicEmphasized,
                                child: widget.isDeleteExpanded
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 6),
                                          Text(
                                            locale.delete.toUpperCase(),
                                            style: const TextStyle(
                                              color: AppTheme.secondaryColor,
                                              fontFamily: 'Oswald',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
