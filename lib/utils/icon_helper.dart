import 'package:flutter/material.dart';

typedef IconWidgetBuilder = Widget Function(Color color, double size);

Widget buildIconWidget(
  dynamic icon, {
  required Color color,
  double size = 18.0,
  IconData defaultIcon = Icons.checkroom,
}) {
  if (icon == null) {
    return Icon(defaultIcon, color: color, size: size);
  }
  if (icon is IconWidgetBuilder) {
    return icon(color, size);
  }
  if (icon is Widget Function(Color, double)) {
    return icon(color, size);
  }
  if (icon is IconData) {
    return Icon(icon, color: color, size: size);
  }
  if (icon is Widget) {
    return icon;
  }
  return Icon(defaultIcon, color: color, size: size);
}
