import 'dart:math';

import 'package:h3_flutter/h3_flutter.dart';

class H3Helper {
  static final H3 h3 = const H3Factory().load();

  static const double _EARTH_CIRC = 40075017;
  static const double _LAT_1DEG = _EARTH_CIRC / 360;

  static List<String> getHexagonsInRadius({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
    required int resolution,
  }) {
    final List<GeoCoord> perimeter = [];

    final double latOffset = radiusMeters / _LAT_1DEG;
    final double lonOffset = radiusMeters / (_LAT_1DEG * cos(centerLat * pi / 180 ));

    for (int a = 45; a <= 360; a += 45) {
      double radians = a * pi / 180;
      perimeter.add(
        GeoCoord(
            lat: centerLat + latOffset * sin(radians),
            lon: centerLon + lonOffset * cos(radians)
        )
      );
    }

    final List<BigInt> cells = h3.polygonToCells(
        perimeter: perimeter,
        resolution: resolution
    );

    return cells.map((cell) => cell.toRadixString(16)).toList();
  }

  static List<String> getHexagonsInViewport({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int resolution,
  }) {
    final List<GeoCoord> perimeter = [
      GeoCoord(lat: minLat, lon: minLon),
      GeoCoord(lat: minLat, lon: maxLon),
      GeoCoord(lat: maxLat, lon: maxLon),
      GeoCoord(lat: maxLat, lon: minLon),
    ];

    final List<BigInt> cells = h3.polygonToCells(
      perimeter: perimeter,
      resolution: resolution,
    );

    return cells.map((cell) => cell.toRadixString(16)).toList();
  }

  static List<List<double>> getHexagonCorners(String h3Index) {
    final BigInt index = BigInt.parse(h3Index, radix: 16);

    final List<GeoCoord> boundary = h3.cellToBoundary(index);

    final List<List<double>> corners = boundary.map((coord) {
      return [coord.lon, coord.lat];
    }).toList();

    if (corners.isNotEmpty) {
      corners.add(corners.first);
    }
    return corners;
  }
}
