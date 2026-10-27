import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class RewardItem {
  final Boost boost;
  final int amount;

  const RewardItem({
    required this.boost,
    required this.amount,
  });
}

class EventDetailsCard extends StatefulWidget {
  final String eventName;
  final int territoriesCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<RewardItem> rewards;
  final Widget? bottomActions;
  final bool initiallyExpanded;

  const EventDetailsCard({
    super.key,
    required this.eventName,
    required this.territoriesCount,
    this.startDate,
    this.endDate,
    this.rewards = const [],
    this.bottomActions,
    this.initiallyExpanded = false,
  });

  @override
  State<EventDetailsCard> createState() => _EventDetailsCardState();
}

class _EventDetailsCardState extends State<EventDetailsCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final activeRewards = widget.rewards.where((r) => r.amount > 0).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubicEmphasized,
        padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        decoration: ShapeDecoration(
          color: AppTheme.darkBackground,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: AppTheme.tertiaryColor,
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale.eventDetailsTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oswald',
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: _isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        if (widget.eventName.isNotEmpty ||
                            widget.territoriesCount > 0 ||
                            (widget.startDate != null && widget.endDate != null) ||
                            activeRewards.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: ShapeDecoration(
                              color: Colors.white.withAlpha(15),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: AppTheme.tertiaryColor.withAlpha(100),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.eventName.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.title,
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.eventNameLabel.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Text(
                                          widget.eventName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Oswald',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (widget.territoriesCount > 0) ...[
                                  if (widget.eventName.isNotEmpty)
                                    const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.map_outlined,
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.territories.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${widget.territoriesCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (widget.startDate != null && widget.endDate != null) ...[
                                  if (widget.eventName.isNotEmpty || widget.territoriesCount > 0)
                                    const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_formatDateTime(widget.startDate)}  ➔  ${_formatDateTime(widget.endDate)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (activeRewards.isNotEmpty) ...[
                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.electric_bolt_sharp,
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.boostRewards.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: activeRewards.map((item) {
                                      final icon = BoostInventory.getBoostIcon(item.boost.type);
                                      final name = item.boost.getCompleteName(locale).toUpperCase();

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: ShapeDecoration(
                                          color: AppTheme.tertiaryColor.withAlpha(40),
                                          shape: BeveledRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            side: BorderSide(
                                              color: AppTheme.tertiaryColor.withAlpha(140),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon, color: Colors.white, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondaryColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'x${item.amount}',
                                                style: const TextStyle(
                                                  color: AppTheme.darkBackground,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (widget.bottomActions != null) ...[
                          const SizedBox(height: 16),
                          widget.bottomActions!,
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: AppTheme.secondaryColor,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
