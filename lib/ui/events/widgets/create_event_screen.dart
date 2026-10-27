import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/ui/core/ui/map_control_group.dart';
import 'package:colonia_front_app/ui/events/widgets/event_details_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/events/view_models/create_event_viewmodel.dart';
import 'package:colonia_front_app/ui/events/widgets/date_time_range_picker_sheet.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

class CreateEventScreen extends StatefulWidget {
  final CreateEventViewModel viewModel;

  const CreateEventScreen({super.key, required this.viewModel});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  String? _lastPaintedHexId;
  bool _isProcessingPointer = false;

  Future<void> _handlePointerMove(PointerEvent event, CreateEventViewModel vm) async {
    if (!vm.inEditMode) return;
    if (_isProcessingPointer) return;

    final map = vm.mapboxMap;
    if (map == null) return;

    _isProcessingPointer = true;
    try {
      final point = await map.coordinateForPixel(
        mapbox.ScreenCoordinate(
          x: event.localPosition.dx,
          y: event.localPosition.dy,
        ),
      );

      final lat = point.coordinates.lat.toDouble();
      final lon = point.coordinates.lng.toDouble();

      final hexId = H3Helper.getHexagonAt(
        lat: lat,
        lon: lon,
        resolution: GameConfig.h3Resolution,
      );

      if (hexId != _lastPaintedHexId) {
        _lastPaintedHexId = hexId;
        HapticFeedback.selectionClick();

        if (vm.mapMode == MapRouteEditMode.paint) {
          vm.paintHexagon(hexId);
        } else if (vm.mapMode == MapRouteEditMode.erase) {
          vm.eraseHexagon(hexId);
        }
      }
    } catch (_) {
    } finally {
      _isProcessingPointer = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (event) => _handlePointerMove(event, vm),
            onPointerMove: (event) => _handlePointerMove(event, vm),
            onPointerUp: (_) => _lastPaintedHexId = null,
            child: mapbox.MapWidget(
              key: const ValueKey("create_event_map"),
              styleUri: mapbox.MapboxStyles.STANDARD,
              onMapCreated: vm.onMapCreated,
              onStyleLoadedListener: (data) async {
                await vm.onStyleLoaded();
              },
              onCameraChangeListener: (data) => vm.onCameraChanged(data),
              viewport: null,
            ),
          ),

          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.tertiaryColor,
                    size: 32.0,
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120, right: 16),
                child: MapControlGroup(
                  listenable: widget.viewModel,
                  currentBearing: widget.viewModel.currentBearing,
                  onCenterOnUser: widget.viewModel.centerOnUser,
                  onResetNorth: widget.viewModel.resetNorth,
                  showPointsButton: false,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IndividualMapButton(
                          icon: Icons.front_hand_sharp,
                          iconColor: vm.mapMode == MapRouteEditMode.navigate? Colors.white : Colors.white.withAlpha(100),
                          borderColor: vm.mapMode == MapRouteEditMode.navigate ? AppTheme.tertiaryColor : Colors.white38,
                          splashColor: AppTheme.tertiaryColor,
                          width: 54,
                          height: 54,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            vm.setMapMode(MapRouteEditMode.navigate);
                          },
                        ),
                        IndividualMapButton(
                          icon: Icons.brush_sharp,
                          iconColor: vm.mapMode == MapRouteEditMode.paint? Colors.white : Colors.white.withAlpha(100),
                          borderColor: vm.mapMode == MapRouteEditMode.paint ? AppTheme.primaryColor : Colors.white38,
                          splashColor: AppTheme.primaryColor,
                          width: 54,
                          height: 54,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            vm.setMapMode(MapRouteEditMode.paint);
                          },
                        ),
                        //const SizedBox(width: 8),
                        IndividualMapButton(
                          icon: Icons.hexagon_outlined,
                          iconColor: vm.mapMode == MapRouteEditMode.erase? Colors.white : Colors.white.withAlpha(100),
                          borderColor: vm.mapMode == MapRouteEditMode.erase? AppTheme.secondaryColor: Colors.white38,
                          splashColor: AppTheme.secondaryColor,
                          width: 54,
                          height: 54,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            vm.setMapMode(MapRouteEditMode.erase);
                          },
                        ),
                        //const SizedBox(width: 8),
                        IndividualMapButton(
                          icon: Icons.clear_sharp,
                          iconColor: Colors.red.shade500,
                          borderColor: Colors.white,
                          splashColor: Colors.red.shade500,
                          width: 54,
                          height: 54,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            vm.clearSelection();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ExpandableEventSummary(
                      name: vm.eventName,
                      startDate: vm.startDate,
                      endDate: vm.endDate,
                      boostRewards: vm.boostQuantities,
                      avatarItemReward: null,
                      territoryCount: 0,
                      viewModel: vm,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableEventSummary extends StatefulWidget {
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<Boost, int> boostRewards;
  final AvatarItem? avatarItemReward;
  final int territoryCount;
  final CreateEventViewModel viewModel;

  const _ExpandableEventSummary({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.boostRewards,
    required this.avatarItemReward,
    required this.territoryCount,
    required this.viewModel,
  });


  @override
  State<_ExpandableEventSummary> createState() => _ExpandableEventSummaryState();
}

class _ExpandableEventSummaryState extends State<_ExpandableEventSummary> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final locale = AppLocalizations.of(context)!;

    final rewards = vm.boostQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => RewardItem(boost: entry.key, amount: entry.value))
        .toList();

    return EventDetailsCard(
      eventName: vm.eventName,
      territoriesCount: vm.selectedHexagonsCount,
      startDate: vm.startDate,
      endDate: vm.endDate,
      rewards: rewards,
      bottomActions: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.tertiaryColor),
                  foregroundColor: AppTheme.primaryColor,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showEventDetailsSheet(context, vm, locale),
                icon: const Icon(Icons.edit_note, size: 20, color: Colors.white),
                label: Text(
                  locale.details,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: AppTheme.darkBackground,
                  disabledBackgroundColor: AppTheme.secondaryColor.withAlpha(80),
                  disabledForegroundColor: Colors.white38,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (vm.isSaveEnabled && !vm.isSaving)
                    ? () async {
                        HapticFeedback.mediumImpact();
                        final success = await vm.saveEvent();
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  locale.eventSavedSuccess(vm.eventName),
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al publicar el evento'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: vm.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBackground,
                        ),
                      )
                    : const Icon(Icons.post_add_sharp, size: 20),
                label: Text(
                  locale.publish.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsSheet(
      BuildContext context, CreateEventViewModel vm, AppLocalizations locale) {
    final nameController = TextEditingController(text: vm.eventName);
    DateTime? tempStart = vm.startDate;
    DateTime? tempEnd = vm.endDate;
    final Map<Boost, int> tempBoosts = Map.from(vm.boostQuantities);

    Widget subtitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            DateTime getEndOfWeekSunday(DateTime date) {
              final daysUntilSunday = DateTime.sunday - date.weekday;
              final sunday = date.add(Duration(days: daysUntilSunday));
              return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
            }

            final maxEndSunday = tempStart != null ? getEndOfWeekSunday(tempStart!) : null;
            final isNameValid = nameController.text.trim().isNotEmpty;
            final isDatesValid = tempStart != null &&
                tempEnd != null &&
                tempEnd!.isAfter(tempStart!) &&
                (maxEndSunday == null || !tempEnd!.isAfter(maxEndSunday));
            final hasRewards = tempBoosts.values.any((q) => q > 0);
            final canConfirm = isNameValid && isDatesValid && hasRewards;

            String formatDateTime(DateTime? dt) {
              if (dt == null) return '';
              return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                color: AppTheme.darkBackground,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            locale.eventDetailsTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Oswald',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      subtitle(locale.eventNameLabel),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: locale.eventNameHint,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withAlpha(15),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),

                      subtitle(locale.dateAndTimeLabel.toUpperCase()),
                      GestureDetector(
                        onTap: () async {
                          final result = await showDateTimeRangePickerSheet(
                            context,
                            initialStart: tempStart,
                            initialEnd: tempEnd,
                          );
                          if (result != null) {
                            setModalState(() {
                              tempStart = result.start;
                              tempEnd = result.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: ShapeDecoration(
                            color: Colors.white.withAlpha(15),
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: (tempStart != null && tempEnd != null)
                                    ? AppTheme.tertiaryColor
                                    : Colors.white24,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_sharp, color: AppTheme.primaryColor, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (tempStart != null && tempEnd != null)
                                      ? '${formatDateTime(tempStart)}  ➔  ${formatDateTime(tempEnd)}'
                                      : locale.dateAndTimeLabel,
                                  style: TextStyle(
                                    color: (tempStart != null && tempEnd != null)
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit, color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),

                      subtitle(locale.boostRewards),
                      Column(
                        children: vm.availableBoosts.map((boost) {
                          final count = tempBoosts[boost] ?? 0;
                          final icon = BoostInventory.getBoostIcon(boost.type);
                          final name = boost.getCompleteName(locale)
                              .toUpperCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: ShapeDecoration(
                              color: count > 0
                                  ? AppTheme.tertiaryColor.withAlpha(50)
                                  : AppTheme.tertiaryColor.withAlpha(20),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: count > 0
                                      ? Colors.white
                                      : AppTheme.tertiaryColor.withAlpha(120),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        icon: const Icon(Icons.remove,
                                            size: 16, color: Colors.white),
                                        onPressed: count > 0
                                            ? () {
                                          setModalState(() {
                                            tempBoosts[boost] = count - 1;
                                          });
                                        }
                                            : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        icon: const Icon(Icons.add,
                                            size: 16, color: Colors.white),
                                        onPressed: () {
                                          setModalState(() {
                                            tempBoosts[boost] = count + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      subtitle(locale.avatarItemRewards),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Colors.white.withAlpha(10),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Colors.white.withAlpha(30),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          locale.noAvatarItems,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tertiaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            AppTheme.tertiaryColor.withAlpha(80),
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: canConfirm
                              ? () {
                            vm.setEventName(nameController.text.trim());
                            if (tempStart != null) vm.setStartDate(tempStart!);
                            if (tempEnd != null) vm.setEndDate(tempEnd!);
                            tempBoosts.forEach((type, qty) {
                              vm.setBoostQuantity(type, qty);
                            });
                            Navigator.pop(context);
                          }
                              : null,
                          child: Text(
                            locale.confirmDetails,
                            style: const TextStyle(
                              fontFamily: 'Oswald',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
