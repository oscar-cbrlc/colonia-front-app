import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/env/env.dart';

class CloudStorageService {
  static Future<String?> uploadUserThumbnail({
    required int userId,
    required Uint8List imageBytes,
    String contentType = 'image/png',
  }) async {
    try {
      final endpointStr = Env.userThumbsEndpoint;
      final accessKey = Env.awsAccess;
      final secretKey = Env.awsSecret;

      final fileName = '$userId.png';

      if (endpointStr.isEmpty) {
        debugPrint('CloudStorageService: userThumbsEndpoint is empty in Env');
        return null;
      }

      var baseUri = Uri.parse(endpointStr.startsWith('http') ? endpointStr : 'https://$endpointStr');
      final scheme = baseUri.scheme.isNotEmpty ? baseUri.scheme : 'https';
      final host = baseUri.host.isNotEmpty ? baseUri.host : endpointStr.replaceFirst(RegExp(r'^https?://'), '').split('/')[0];

      final uploadPath = '${baseUri.path.isEmpty || baseUri.path == '/' ? '' : baseUri.path}/$fileName';
      final uploadUri = Uri(
        scheme: scheme,
        host: host,
        path: uploadPath,
      );

      final String fullUrl = uploadUri.toString();

      debugPrint('CloudStorageService: Uploading thumbnail for user $userId to $fullUrl');

      final now = DateTime.now().toUtc();
      final dateStr = _formatAmzDate(now);
      final shortDateStr = dateStr.substring(0, 8);

      String region = 'us-west-2';
      final hostParts = host.split('.');
      for (final part in hostParts) {
        if (part.startsWith('us-') || part.startsWith('eu-') || part.startsWith('ap-') || part.startsWith('sa-') || part.startsWith('ca-')) {
          region = part;
          break;
        }
      }

      final payloadHash = sha256.convert(imageBytes).toString();

      final headers = <String, String>{
        'Content-Type': contentType,
        'Host': host,
        'x-amz-acl': 'public-read',
        'x-amz-date': dateStr,
        'x-amz-content-sha256': payloadHash,
      };

      if (accessKey.isNotEmpty && secretKey.isNotEmpty) {
        final authHeader = _buildSigV4Header(
          method: 'PUT',
          uri: uploadUri,
          headers: headers,
          payloadHash: payloadHash,
          accessKey: accessKey,
          secretKey: secretKey,
          region: region,
          service: 's3',
          dateStr: dateStr,
          shortDateStr: shortDateStr,
        );
        headers['Authorization'] = authHeader;
      }

      final response = await http.put(
        uploadUri,
        headers: headers,
        body: imageBytes,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('CloudStorageService: Upload succeeded ($fullUrl)');
        return fullUrl;
      } else {
        debugPrint('CloudStorageService: S3 response status ${response.statusCode}: ${response.body}');
        return fullUrl;
      }
    } catch (e, stackTrace) {
      debugPrint('CloudStorageService: Exception uploading thumbnail: $e\n$stackTrace');
      final endpointStr = Env.userThumbsEndpoint;
      if (endpointStr.isNotEmpty) {
        final base = endpointStr.endsWith('/') ? endpointStr.substring(0, endpointStr.length - 1) : endpointStr;
        return '$base/$userId.png';
      }
    }
    return null;
  }

  static String _formatAmzDate(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${pad(dt.month)}${pad(dt.day)}T${pad(dt.hour)}${pad(dt.minute)}${pad(dt.second)}Z';
  }

  static String _buildSigV4Header({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String payloadHash,
    required String accessKey,
    required String secretKey,
    required String region,
    required String service,
    required String dateStr,
    required String shortDateStr,
  }) {
    final canonicalUri = uri.path.isEmpty ? '/' : uri.path;
    const canonicalQueryString = '';

    final sortedHeaders = headers.keys.map((k) => k.toLowerCase()).toList()..sort();
    final canonicalHeaders = sortedHeaders.map((k) => '$k:${headers.entries.firstWhere((e) => e.key.toLowerCase() == k).value.trim()}\n').join();
    final signedHeaders = sortedHeaders.join(';');

    final canonicalRequest = [
      method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$shortDateStr/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      dateStr,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), shortDateStr);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, 'aws4_request');

    final signature = _hmacSha256Hex(kSigning, stringToSign);

    return 'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';
  }

  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }
}
