import 'package:intl/intl.dart';

NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');
NumberFormat _decimalFormat = NumberFormat('#,##0.0', 'en_US');

String formatNumber(int num) {
  return _numberFormat.format(num);
}