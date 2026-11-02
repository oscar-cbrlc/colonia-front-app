import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class GlbMerger {
  static Future<File?> mergeGlbFiles({
    required List<Uint8List> glbBytesList,
    required String outputPath,
    List<double>? baseColorFactor,
  }) async {
    if (glbBytesList.isEmpty) return null;
    if (glbBytesList.length == 1 && baseColorFactor == null) {
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(glbBytesList.first);
      return outputFile;
    }

    try {
      final parsedGlbs = <_ParsedGlb>[];
      for (final bytes in glbBytesList) {
        final parsed = _parseGlb(bytes);
        if (parsed != null) {
          parsedGlbs.add(parsed);
        }
      }

      if (parsedGlbs.isEmpty) return null;

      final base = parsedGlbs.first;
      final mergedJson = Map<String, dynamic>.from(base.json);

      var combinedBin = BytesBuilder();
      combinedBin.add(base.binBytes);

      mergedJson['nodes'] = List<dynamic>.from(mergedJson['nodes'] ?? []);
      mergedJson['meshes'] = List<dynamic>.from(mergedJson['meshes'] ?? []);
      mergedJson['materials'] = List<dynamic>.from(mergedJson['materials'] ?? []);

      // Apply baseColorFactor to base GLB materials if specified
      if (baseColorFactor != null && (mergedJson['materials'] as List).isNotEmpty) {
        for (var i = 0; i < (mergedJson['materials'] as List).length; i++) {
          final mat = Map<String, dynamic>.from(mergedJson['materials'][i]);
          final pbr = Map<String, dynamic>.from(mat['pbrMetallicRoughness'] ?? {});
          pbr['baseColorFactor'] = baseColorFactor;
          mat['pbrMetallicRoughness'] = pbr;
          mergedJson['materials'][i] = mat;
        }
      }
      mergedJson['accessors'] = List<dynamic>.from(mergedJson['accessors'] ?? []);
      mergedJson['bufferViews'] = List<dynamic>.from(mergedJson['bufferViews'] ?? []);
      mergedJson['textures'] = List<dynamic>.from(mergedJson['textures'] ?? []);
      mergedJson['images'] = List<dynamic>.from(mergedJson['images'] ?? []);
      mergedJson['samplers'] = List<dynamic>.from(mergedJson['samplers'] ?? []);

      var baseNodeCount = (mergedJson['nodes'] as List).length;
      var baseMeshCount = (mergedJson['meshes'] as List).length;
      var baseMaterialCount = (mergedJson['materials'] as List).length;
      var baseAccessorCount = (mergedJson['accessors'] as List).length;
      var baseBufferViewCount = (mergedJson['bufferViews'] as List).length;
      var baseTextureCount = (mergedJson['textures'] as List).length;
      var baseImageCount = (mergedJson['images'] as List).length;
      var baseSamplerCount = (mergedJson['samplers'] as List).length;

      final scenes = List<dynamic>.from(mergedJson['scenes'] ?? []);
      if (scenes.isNotEmpty) {
        final primaryScene = Map<String, dynamic>.from(scenes[0]);
        primaryScene['nodes'] = List<dynamic>.from(primaryScene['nodes'] ?? []);
        mergedJson['scenes'][0] = primaryScene;
      }

      for (var i = 1; i < parsedGlbs.length; i++) {
        final current = parsedGlbs[i];
        final currentJson = current.json;
        final currentBinOffset = combinedBin.length;

        final binPadding = (4 - (currentBinOffset % 4)) % 4;
        if (binPadding > 0) {
          combinedBin.add(Uint8List(binPadding));
        }
        final alignedBinOffset = combinedBin.length;
        combinedBin.add(current.binBytes);

        final nodeOffset = baseNodeCount;
        final meshOffset = baseMeshCount;
        final materialOffset = baseMaterialCount;
        final accessorOffset = baseAccessorCount;
        final bufferViewOffset = baseBufferViewCount;
        final textureOffset = baseTextureCount;
        final imageOffset = baseImageCount;
        final samplerOffset = baseSamplerCount;

        for (final bv in List<dynamic>.from(currentJson['bufferViews'] ?? [])) {
          final newBv = Map<String, dynamic>.from(bv);
          newBv['buffer'] = 0;
          newBv['byteOffset'] = ((newBv['byteOffset'] as num?) ?? 0) + alignedBinOffset;
          (mergedJson['bufferViews'] as List).add(newBv);
        }

        for (final acc in List<dynamic>.from(currentJson['accessors'] ?? [])) {
          final newAcc = Map<String, dynamic>.from(acc);
          if (newAcc.containsKey('bufferView')) {
            newAcc['bufferView'] = (newAcc['bufferView'] as int) + bufferViewOffset;
          }
          (mergedJson['accessors'] as List).add(newAcc);
        }

        for (final s in (currentJson['samplers'] as List? ?? [])) {
          (mergedJson['samplers'] as List).add(Map<String, dynamic>.from(s));
        }
        for (final img in (currentJson['images'] as List? ?? [])) {
          final newImg = Map<String, dynamic>.from(img);
          if (newImg.containsKey('bufferView')) {
            newImg['bufferView'] = (newImg['bufferView'] as int) + bufferViewOffset;
          }
          (mergedJson['images'] as List).add(newImg);
        }
        for (final tex in (currentJson['textures'] as List? ?? [])) {
          final newTex = Map<String, dynamic>.from(tex);
          if (newTex.containsKey('sampler')) {
            newTex['sampler'] = (newTex['sampler'] as int) + samplerOffset;
          }
          if (newTex.containsKey('source')) {
            newTex['source'] = (newTex['source'] as int) + imageOffset;
          }
          (mergedJson['textures'] as List).add(newTex);
        }

        for (final mat in (currentJson['materials'] as List? ?? [])) {
          final newMat = Map<String, dynamic>.from(mat);
          if (newMat.containsKey('pbrMetallicRoughness')) {
            final pbr = Map<String, dynamic>.from(newMat['pbrMetallicRoughness']);
            if (pbr.containsKey('baseColorTexture')) {
              final tex = Map<String, dynamic>.from(pbr['baseColorTexture']);
              tex['index'] = (tex['index'] as int) + textureOffset;
              pbr['baseColorTexture'] = tex;
            }
            newMat['pbrMetallicRoughness'] = pbr;
          }
          (mergedJson['materials'] as List).add(newMat);
        }

        for (final mesh in (currentJson['meshes'] as List? ?? [])) {
          final newMesh = Map<String, dynamic>.from(mesh);
          final newPrimitives = <Map<String, dynamic>>[];

          for (final prim in List<dynamic>.from(newMesh['primitives'] ?? [])) {
            final newPrim = Map<String, dynamic>.from(prim);
            if (newPrim.containsKey('material')) {
              newPrim['material'] = (newPrim['material'] as int) + materialOffset;
            }
            if (newPrim.containsKey('indices')) {
              newPrim['indices'] = (newPrim['indices'] as int) + accessorOffset;
            }
            if (newPrim.containsKey('attributes')) {
              final attrs = Map<String, dynamic>.from(newPrim['attributes']);
              attrs.forEach((key, val) {
                attrs[key] = (val as int) + accessorOffset;
              });
              newPrim['attributes'] = attrs;
            }
            newPrimitives.add(newPrim);
          }
          newMesh['primitives'] = newPrimitives;
          (mergedJson['meshes'] as List).add(newMesh);
        }

        for (final node in (currentJson['nodes'] as List? ?? [])) {
          final newNode = Map<String, dynamic>.from(node);
          if (newNode.containsKey('mesh')) {
            newNode['mesh'] = (newNode['mesh'] as int) + meshOffset;
          }
          if (newNode.containsKey('children')) {
            newNode['children'] = (newNode['children'] as List).map((c) => (c as int) + nodeOffset).toList();
          }
          (mergedJson['nodes'] as List).add(newNode);
        }

        final currentScenes = List<dynamic>.from(currentJson['scenes'] ?? []);
        if (currentScenes.isNotEmpty) {
          final rootNodes = List<int>.from(currentScenes[0]['nodes'] ?? []);
          for (final rn in rootNodes) {
            (mergedJson['scenes'][0]['nodes'] as List).add(rn + nodeOffset);
          }
        }

        baseNodeCount = (mergedJson['nodes'] as List).length;
        baseMeshCount = (mergedJson['meshes'] as List).length;
        baseMaterialCount = (mergedJson['materials'] as List).length;
        baseAccessorCount = (mergedJson['accessors'] as List).length;
        baseBufferViewCount = (mergedJson['bufferViews'] as List).length;
        baseTextureCount = (mergedJson['textures'] as List).length;
        baseImageCount = (mergedJson['images'] as List).length;
        baseSamplerCount = (mergedJson['samplers'] as List).length;
      }

      mergedJson['buffers'] = [{'byteLength': combinedBin.length}];

      final finalJsonString = jsonEncode(mergedJson);
      var finalJsonBytes = Uint8List.fromList(utf8.encode(finalJsonString));

      final remainder = finalJsonBytes.length % 4;
      if (remainder != 0) {
        final padCount = 4 - remainder;
        final padded = Uint8List(finalJsonBytes.length + padCount);
        padded.setAll(0, finalJsonBytes);
        for (var i = finalJsonBytes.length; i < padded.length; i++) {
          padded[i] = 0x20;
        }
        finalJsonBytes = padded;
      }

      final finalBinBytes = combinedBin.toBytes();
      final totalGlbLength = 12 + 8 + finalJsonBytes.length + 8 + finalBinBytes.length;

      final outputBytes = Uint8List(totalGlbLength);
      final byteData = outputBytes.buffer.asByteData();

      outputBytes.setAll(0, utf8.encode('glTF'));
      byteData.setUint32(4, 2, Endian.little);
      byteData.setUint32(8, totalGlbLength, Endian.little);

      byteData.setUint32(12, finalJsonBytes.length, Endian.little);
      outputBytes.setAll(16, utf8.encode('JSON'));
      outputBytes.setAll(20, finalJsonBytes);

      final binHeaderOffset = 20 + finalJsonBytes.length;
      byteData.setUint32(binHeaderOffset, finalBinBytes.length, Endian.little);
      outputBytes.setAll(binHeaderOffset + 4, [0x42, 0x49, 0x4E, 0x00]);
      outputBytes.setAll(binHeaderOffset + 8, finalBinBytes);

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);
      return outputFile;
    } catch (e, stack) {
      debugPrint("GlbMerger failed: $e\n$stack");
      return null;
    }
  }

  static _ParsedGlb? _parseGlb(Uint8List bytes) {
    if (bytes.length < 20) return null;

    final magic = utf8.decode(bytes.sublist(0, 4));
    if (magic != 'glTF') {
      debugPrint("GlbMerger: Invalid GLB magic header ($magic)");
      return null;
    }

    final byteData = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);

    final jsonChunkLength = byteData.getUint32(12, Endian.little);
    final jsonChunkType = utf8.decode(bytes.sublist(16, 20));
    if (jsonChunkType != 'JSON') {
      debugPrint("GlbMerger: Invalid Chunk 0 type ($jsonChunkType)");
      return null;
    }

    final jsonStart = 20;
    final jsonEnd = jsonStart + jsonChunkLength;
    if (jsonEnd > bytes.length) return null;

    final jsonBytes = bytes.sublist(jsonStart, jsonEnd);
    final jsonMap = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

    final binHeaderOffset = jsonEnd;
    if (binHeaderOffset + 8 > bytes.length) {
      return _ParsedGlb(jsonMap, Uint8List(0));
    }

    final binChunkLength = byteData.getUint32(binHeaderOffset, Endian.little);
    final binStart = binHeaderOffset + 8;
    final binEnd = (binStart + binChunkLength).clamp(binStart, bytes.length);

    final binBytes = bytes.sublist(binStart, binEnd);
    return _ParsedGlb(jsonMap, binBytes);
  }
}

class _ParsedGlb {
  final Map<String, dynamic> json;
  final Uint8List binBytes;

  _ParsedGlb(this.json, this.binBytes);
}