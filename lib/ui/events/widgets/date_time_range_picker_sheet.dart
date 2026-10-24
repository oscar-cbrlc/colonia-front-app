import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

Future<({DateTime start, DateTime end})?> showDateTimeRangePickerSheet(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  return showModalBottomSheet<({DateTime start, DateTime end})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DateTimeRangePickerSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class DateTimeRangePickerSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const DateTimeRangePickerSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<DateTimeRangePickerSheet> createState() => _DateTimeRangePickerSheetState();
}

class _DateTimeRangePickerSheetState extends State<DateTimeRangePickerSheet> {
  late DateTime _displayedMonth;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  int _startHour = 9;
  int _startMinute = 0;
  int _endHour = 23;
  int _endMinute = 59;

  DateTime? get maxSunday => _selectedStart != null ? _getEndOfWeekSunday(_selectedStart!) : null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedStart = widget.initialStart ?? now;
    _selectedEnd = widget.initialEnd ?? _getEndOfWeekSunday(_selectedStart!);

    _displayedMonth = DateTime(_selectedStart!.year, _selectedStart!.month, 1);

    _startHour = _selectedStart!.hour;
    _startMinute = _selectedStart!.minute;
    _endHour = _selectedEnd!.hour;
    _endMinute = _selectedEnd!.minute;
  }

  DateTime _getEndOfWeekSunday(DateTime date) {
    final daysUntilSunday = DateTime.sunday - date.weekday;
    final sunday = date.add(Duration(days: daysUntilSunday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDaySelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedStart == null) {
        _selectedStart = date;
      } else {
        if (_isSameDay(_selectedStart!, date)) {
          _selectedEnd = date;
          return;
        }
        if (_selectedEnd == null) {
          if (!date.isBefore(_selectedStart!)) {
            _selectedEnd = date;
          } else {
            _selectedStart = date;
            _selectedEnd = null;
          }
        } else {
          if (date.isAfter(_selectedEnd!)) {
            _selectedStart = date;
            _selectedEnd = null;
          } else {
            _selectedStart = date;
            if (_selectedEnd!.isBefore(_selectedStart!)) {
              _selectedEnd = _selectedStart;
              _selectedStart = date;
            }
            if (_selectedEnd!.isAfter(maxSunday!)) {
              _selectedEnd = maxSunday;
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final finalStart = _selectedStart != null
        ? DateTime(_selectedStart!.year, _selectedStart!.month, _selectedStart!.day, _startHour, _startMinute)
        : null;
    final finalEnd = _selectedEnd != null
        ? DateTime(_selectedEnd!.year, _selectedEnd!.month, _selectedEnd!.day, _endHour, _endMinute)
        : null;

    final isValidRange = finalStart != null &&
        finalEnd != null &&
        finalEnd.isAfter(finalStart) &&
        (maxSunday == null || !finalEnd.isAfter(maxSunday!));

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
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
                    locale.dateAndTimeLabel.toUpperCase(),
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
              const SizedBox(height: 12),

              Text(
                ((locale as dynamic).eventScheduleLabel as String?) ?? 'HORARIO DEL EVENTO',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerTile(
                      label: ((locale as dynamic).startTimeLabel as String?) ?? 'HORA INICIO',
                      hour: _startHour,
                      minute: _startMinute,
                      color: AppTheme.tertiaryColor,
                      onChanged: (h, m) {
                        setState(() {
                          _startHour = h;
                          _startMinute = m;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildTimePickerTile(
                      label: ((locale as dynamic).endTimeLabel as String?) ?? 'HORA FIN',
                      hour: _endHour,
                      minute: _endMinute,
                      color: AppTheme.secondaryColor,
                      onChanged: (h, m) {
                        setState(() {
                          _endHour = h;
                          _endMinute = m;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    _formatMonthYear(locale, _displayedMonth).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  locale.mondayShort,
                  locale.tuesdayShort,
                  locale.wednesdayShort,
                  locale.thursdayShort,
                  locale.fridayShort,
                  locale.saturdayShort,
                  locale.sundayShort
                ].map((day) {
                  return SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              _buildCalendarGrid(today, maxSunday),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: ShapeDecoration(
                        color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor.withAlpha(40) : AppTheme.tertiaryColor.withAlpha(40),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor : AppTheme.tertiaryColor, width: 1.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: ShapeDecoration(
                                  color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor : AppTheme.tertiaryColor,
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                locale.startTimestamp.toUpperCase(),
                                style: TextStyle(
                                  color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? Colors.white : AppTheme.tertiaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            finalStart != null ? _formatDateTime(finalStart) : '--/--/---- --:--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: ShapeDecoration(
                        color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor.withAlpha(40) : AppTheme.secondaryColor.withAlpha(40),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor : AppTheme.secondaryColor, width: 1.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: ShapeDecoration(
                                  color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? AppTheme.primaryColor : AppTheme.secondaryColor,
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                locale.endTimestamp.toUpperCase(),
                                style: TextStyle(
                                  color: finalStart != null && finalEnd != null  && _isSameDay(finalStart, finalEnd)? Colors.white : AppTheme.secondaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            finalEnd != null ? _formatDateTime(finalEnd) : '--/--/---- --:--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.tertiaryColor.withAlpha(80),
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isValidRange
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(
                            context,
                            (start: finalStart, end: finalEnd),
                          );
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
  }

  Widget _buildCalendarGrid(DateTime today, DateTime? maxSundayDate) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday;

    final gridCells = <Widget>[];

    for (int i = 1; i < firstWeekday; i++) {
      gridCells.add(const SizedBox(width: 36, height: 36));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(year, month, day);

      final isStart = _selectedStart != null && _isSameDay(cellDate, _selectedStart!);
      final isEnd = _selectedEnd != null && _isSameDay(cellDate, _selectedEnd!);
      final isSameDay = _selectedStart != null &&
          _selectedEnd != null &&
          _isSameDay(cellDate, _selectedStart!) &&
          _isSameDay(cellDate, _selectedEnd!);
      final isInRange = _selectedStart != null &&
          _selectedEnd != null &&
          cellDate.isAfter(_selectedStart!) &&
          cellDate.isBefore(_selectedEnd!);

      final isBeforeToday = cellDate.isBefore(today);
      final isPastMaxSunday = maxSundayDate != null && cellDate.isAfter(maxSundayDate);
      final isDisabled = isBeforeToday || isPastMaxSunday;

      Color bgColor = Colors.transparent;
      ShapeBorder shape = const RoundedRectangleBorder();

      if (isSameDay) {
        bgColor = AppTheme.primaryColor;
        shape = const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        );
      } else if (isStart) {
        bgColor = AppTheme.tertiaryColor;
        shape = const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        );
      } else if (isEnd) {
        bgColor = AppTheme.secondaryColor;
        shape = const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
        );
      } else if (isInRange) {
        bgColor = AppTheme.tertiaryColor.withAlpha(50);
      }

      gridCells.add(
        GestureDetector(
          onTap:  () => _onDaySelected(cellDate),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: ShapeDecoration(
              color: bgColor,
              shape: shape,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isDisabled
                      ? Colors.white12
                      : (isStart || isEnd
                          ? Colors.white
                          : (isInRange ? AppTheme.primaryColor : Colors.white70)),
                  fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: gridCells,
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required int hour,
    required int minute,
    required Color color,
    required void Function(int hour, int minute) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(15),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withAlpha(180), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScrollableWheelPicker(
                value: hour,
                count: 24,
                step: 1,
                color: color,
                onChanged: (newHour) => onChanged(newHour, minute),
              ),
              const Text(
                ':',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Oswald',
                ),
              ),
              _ScrollableWheelPicker(
                value: minute,
                count: 60,
                step: 1,
                color: color,
                onChanged: (newMinute) => onChanged(hour, newMinute),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatMonthYear(AppLocalizations locale, DateTime dt) {
    var months = [
      locale.januaryLabel, locale.februaryLabel, locale.marchLabel,
      locale.aprilLabel, locale.mayLabel, locale.juneLabel,
      locale.julyLabel, locale.augustLabel, locale.septemberLabel,
      locale.octoberLabel, locale.novemberLabel, locale.decemberLabel
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _ScrollableWheelPicker extends StatelessWidget {
  final int value;
  final int count;
  final int step;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ScrollableWheelPicker({
    required this.value,
    required this.count,
    this.step = 1,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: 44,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 26,
        perspective: 0.004,
        diameterRatio: 4.5,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: (value ~/ step) % (count ~/ step)),
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          onChanged((index * step) % count);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count ~/ step,
          builder: (context, index) {
            final itemValue = (index * step) % count;
            final isSelected = itemValue == value;
            return Center(
              child: Text(
                itemValue.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 24 : 16,
                  fontFamily: 'Oswald',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
