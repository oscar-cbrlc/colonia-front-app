import 'package:borders/borders.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:colonia_front_app/env/env.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.viewModel});
  final MapViewModel viewModel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final colors = [Colors.amber, Colors.black, Colors.blue];

  int _accuracyColor = 0;
  int _pulsingColor = 0;
  int _accuracyBorderColor = 0;
  double _puckScale = 10.0;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(Env.mapboxAccessToken);
    widget.viewModel.requestLocationPermission();
  }

  void _show(MapboxMap mapboxMap) {
    mapboxMap.location
        .updateSettings(LocationComponentSettings(enabled: true));
  }

  void _hide(MapboxMap mapboxMap) {
    mapboxMap.location
       .updateSettings(LocationComponentSettings(enabled: false));
  }

  void _showBearing(MapboxMap mapboxMap) {
    mapboxMap.location.updateSettings(
      LocationComponentSettings(puckBearingEnabled: true));
  }

  void _hideBearing(MapboxMap mapboxMap) {
    mapboxMap.location.updateSettings(
      LocationComponentSettings(puckBearingEnabled: false));
  }

  void _showPulsing(MapboxMap mapboxMap) {
    mapboxMap.location
        .updateSettings(LocationComponentSettings(pulsingEnabled: true));
  }

  void _hidePulsing(MapboxMap mapboxMap) {
    mapboxMap.location
        .updateSettings(LocationComponentSettings(pulsingEnabled: false));
  }

  void _showAccuracy(MapboxMap mapboxMap) {
    mapboxMap.location
        .updateSettings(LocationComponentSettings(showAccuracyRing: true));
  }

  void _hideAccuracy(MapboxMap mapboxMap) {
    mapboxMap.location
        .updateSettings(LocationComponentSettings(showAccuracyRing: false));
  }

  void _changeAccuracyBorderColor(MapboxMap mapboxMap, Color color) {
    mapboxMap.location.updateSettings(
        LocationComponentSettings(
          accuracyRingBorderColor: color.toARGB32()
        )
    );
  }

  void _changeAccuracyColor(MapboxMap mapboxMap, Color color) {
    mapboxMap.location.updateSettings(LocationComponentSettings(
        accuracyRingColor: color.toARGB32()));
  }

  void _changePulsingColor(MapboxMap mapboxMap, Color color) {
        _accuracyColor++;
        _accuracyColor %= colors.length;
        mapboxMap.location.updateSettings(LocationComponentSettings(
            pulsingColor: color.toARGB32()));

  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              MapWidget(
                key: const ValueKey("mapWidget"),
                onMapCreated: widget.viewModel.onMapCreated,
                viewport: widget.viewModel.viewport ?? CameraViewportState(
                  center: Point(coordinates: Position(0, 0)),
                  zoom: 12.0,
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // TODO: Insert buttons
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) {
                              final buttonShape = ChamferBorder(
                                side: BorderSide(
                                  color: AppTheme.boostPrimaryIconColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
                                borderChamfer: BorderChamfer.vertical(top: true),
                              );

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 80,
                                height: 80,
                                decoration:  ShapeDecoration(
                                  color: AppTheme.boostPrimaryColor,
                                  shape: buttonShape,

                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: buttonShape,
                                    onTap: () {
                                      //widget.viewModel.centerOnUser();
                                    },
                                    child: const Center(
                                      child: Icon(
                                        Icons.shield_outlined,
                                        color: AppTheme.boostPrimaryIconColor,
                                        size: 48.0,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                          },
                        ),
                      ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
