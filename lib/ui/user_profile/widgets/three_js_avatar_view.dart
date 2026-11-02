import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class ThreeJsAvatarView extends StatefulWidget {
  final String baseGlbPath;
  final List<String> equippedGlbPaths;
  final Color? avatarColor;

  const ThreeJsAvatarView({
    super.key,
    required this.baseGlbPath,
    required this.equippedGlbPaths,
    this.avatarColor,
  });

  @override
  State<ThreeJsAvatarView> createState() => _ThreeJsAvatarViewState();
}

class _ThreeJsAvatarViewState extends State<ThreeJsAvatarView> {
  static final Map<String, Uint8List> _modelByteCache = {};
  static final Map<String, three.Object3D> _parsedModelCache = {};

  late three.ThreeJS _threeJS;
  final three.Group _avatarGroup = three.Group();
  three.OrbitControls? _orbitControls;
  int _loadVersion = 0;
  bool _isLoading = true;
  bool _isCameraFramed = false;

  @override
  void initState() {
    super.initState();
    _threeJS = three.ThreeJS(
      settings: three.Settings(
        clearColor: 0x00000000,
        alpha: true,
      ),
      setup: () async {
        _threeJS.scene = three.Scene();
        _threeJS.camera = three.PerspectiveCamera(
          45,
          1,
          0.1,
          2000,
        );

        _threeJS.scene.add(_avatarGroup);
        _threeJS.scene.add(three.AmbientLight(0xffffff, 1));
        final directionalLight = three.DirectionalLight(0xffffff, 1);
        directionalLight.position.setValues(0, 1, 1);
        _threeJS.scene.add(directionalLight);
        _threeJS.renderer?.setClearColor(three.Color(0x000000), 0);
      },
      onSetupComplete: () async {
        _orbitControls = three.OrbitControls(
          _threeJS.camera,
          _threeJS.globalKey,
        );
        _orbitControls!.enablePan = false;

        await _reloadAllModels();

        if (!_isCameraFramed && _avatarGroup.children.isNotEmpty) {
          _fitCameraToGroup();
          _isCameraFramed = true;
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _fitCameraToGroup() {
    final box = three.BoundingBox();

    _avatarGroup.traverse((child) {
      if (child is three.Mesh && child.geometry != null) {
        child.geometry!.computeBoundingBox();
        if (child.geometry!.boundingBox != null) {
          final childBox = child.geometry!.boundingBox!.clone();
          childBox.applyMatrix4(child.matrixWorld);
          box.union(childBox);
        }
      }
    });

    if (box.isEmpty()) {
      box.setFromObject(_avatarGroup);
    }

    if (box.isEmpty()) return;

    final center = three.Vector3();
    box.getCenter(center);

    final size = three.Vector3();
    box.getSize(size);

    double maxDim = math.max(size.x, math.max(size.y, size.z));
    if (maxDim <= 0) maxDim = 1.0;

    final camera = _threeJS.camera as three.PerspectiveCamera;
    camera.aspect = 1.0;
    final fovRad = camera.fov * (math.pi / 180.0);

    double distance = (maxDim / (2 * math.tan(fovRad / 2))) * 1.2;

    camera.near = (distance / 100).clamp(0.01, 10.0);
    camera.far = distance * 100;
    camera.position.setValues(center.x, center.y, center.z + distance);
    camera.lookAt(center);
    camera.updateProjectionMatrix();

    if (_orbitControls != null) {
      _orbitControls!.target.setFrom(center);
      _orbitControls!.enablePan = false;
      _orbitControls!.minDistance = distance * 0.6;
      _orbitControls!.maxDistance = distance * 1.6;
      _orbitControls!.update();
    }
  }

  @override
  void didUpdateWidget(covariant ThreeJsAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.equippedGlbPaths, widget.equippedGlbPaths) ||
        oldWidget.baseGlbPath != widget.baseGlbPath ||
        oldWidget.avatarColor != widget.avatarColor) {
      _reloadAllModels();
    }
  }

  Future<void> _reloadAllModels() async {
    final version = ++_loadVersion;

    final isUncached = !_parsedModelCache.containsKey(widget.baseGlbPath) ||
        widget.equippedGlbPaths.any((p) => !_parsedModelCache.containsKey(p));

    if (isUncached && !_isLoading) {
      _isLoading = true;
      if (mounted) setState(() {});
    }

    final loadedObjects = <three.Object3D>[];

    final baseObj = await _loadModelPath(widget.baseGlbPath, isBase: true);
    if (version != _loadVersion) return;
    if (baseObj != null) loadedObjects.add(baseObj);

    for (final itemPath in widget.equippedGlbPaths) {
      if (version != _loadVersion) return;
      final itemObj = await _loadModelPath(itemPath, isBase: false);
      if (itemObj != null) loadedObjects.add(itemObj);
    }

    if (version != _loadVersion) return;

    while (_avatarGroup.children.isNotEmpty) {
      _avatarGroup.remove(_avatarGroup.children.first);
    }
    for (final obj in loadedObjects) {
      _avatarGroup.add(obj);
    }

    if (!_isCameraFramed && _avatarGroup.children.isNotEmpty) {
      _fitCameraToGroup();
      _isCameraFramed = true;
    }

    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<three.Object3D?> _loadModelPath(String path, {bool isBase = false}) async {
    if (path.isEmpty) return null;
    try {
      three.Object3D? masterObj = _parsedModelCache[path];

      if (masterObj == null) {
        final bytes = await _getBytesForPath(path);
        if (bytes == null) return null;

        final loader = three.GLTFLoader();
        final gltf = await loader.fromBytes(bytes);
        masterObj = gltf?.scene;
        if (masterObj != null) {
          _parsedModelCache[path] = masterObj;
        }
      }

      if (masterObj == null) return null;

      final clonedObj = masterObj.clone(true);

      clonedObj.traverse((child) {
        if (child is three.Mesh) {
          final mat = child.material;

          if (mat != null) {
            mat.transparent = false;
            mat.opacity = 1.0;
            mat.depthWrite = true;
            mat.depthTest = true;
            mat.blending = three.NormalBlending;
            mat.needsUpdate = true;
          }

          if (isBase && widget.avatarColor != null) {
            child.material = child.material?.clone();

            if (child.material is three.MeshStandardMaterial) {
              final stdMat = child.material as three.MeshStandardMaterial;
              final c = widget.avatarColor!;
              stdMat.color = three.Color(c.r, c.g, c.b);
              stdMat.needsUpdate = true;
            }
          }
        }
      });

      return clonedObj;
    } catch (e, stackTrace) {
      debugPrint("Error loading 3D model ($path): $e\n$stackTrace");
      return null;
    }
  }

  Future<Uint8List?> _getBytesForPath(String path) async {
    if (_modelByteCache.containsKey(path)) {
      return _modelByteCache[path];
    }

    try {
      Uint8List? bytes;
      if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      } else {
        final cleanPath = path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
        final file = File(cleanPath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          debugPrint("3D model file does not exist on disk: $cleanPath");
        }
      }

      if (bytes != null) {
        _modelByteCache[path] = bytes;
      }
      return bytes;
    } catch (e, stackTrace) {
      debugPrint("Error fetching bytes for 3D model ($path): $e\n$stackTrace");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _threeJS.build(),
        if (_isLoading)
          Container(
            color: Colors.black38,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const HueSlider({super.key, required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double thumbRadius = 12.0;
        final double thumbLeft = ((hue / 360.0) * width - thumbRadius).clamp(0.0, width - thumbRadius * 2);

        return GestureDetector(
          onPanUpdate: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          onTapDown: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
