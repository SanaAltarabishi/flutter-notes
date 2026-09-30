import 'dart:convert';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freenotes_app/core/errors/exceptions.dart';
import 'package:freenotes_app/features/notes/data/datasources/remote/myscript_remote_datasource.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/stroke.dart';

class MyScriptRemoteDataSourceImpl implements MyScriptRemoteDataSource {
  final Dio dio;
  MyScriptRemoteDataSourceImpl({required this.dio});

  // ───────────────────────────────────────────────
  @override
  Future<String> recognizeText(List<Stroke> strokes, String language) =>
      _recognize(strokes, language, 'Text');

  @override
  Future<String> recognizeShape(List<Stroke> strokes) =>
      _recognize(strokes, 'en_US', 'Shape');
  // ───────────────────────────────────────────────
  //  HMAC
  String _generateHmac(String body) {
    const userKey =
        AppConstants.myScriptApplicationKey + AppConstants.myScriptHmacKey;
    final hmac = Hmac(sha512, utf8.encode(userKey));
    return hmac.convert(utf8.encode(body)).toString();
  }

  // ───────────────────────────────────────────────
  //Payload
  Map<String, dynamic> _buildPayload(
    List<Stroke> strokes,
    String language,
    String contentType,
  ) {
    final strokesData = strokes.map((stroke) {
      return {
        'x': stroke.points.map((p) => p.x.toInt()).toList(),
        'y': stroke.points.map((p) => p.y.toInt()).toList(),
        't': List.generate(stroke.points.length, (i) => i * 10),
        'pointerType': 'PEN', //'TOUCH'
      };
    }).toList();
/*
points before:
(10,20)
(15,25)
(20,30)
------------------------------
after :
"x": [10, 15, 20]
"y": [20, 25, 30]

*/
    final dpi =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio * 160.0;
    final scale = 25.4 / dpi;

    return {
      'contentType': contentType,
      'configuration': {'lang': language},
      'strokes': strokesData,
      'scaleX': scale,
      'scaleY': scale,
    };
  }

  // ───────────────────────────────────────────────
  Future<String> _recognize(
    List<Stroke> strokes,
    String language,
    String contentType,
  ) async {
    try {
      final payload = _buildPayload(strokes, language, contentType);
      final body = jsonEncode(payload); //from map to json(string)
      final hmac = _generateHmac(body);

      debugPrint('📡 POST → ${AppConstants.myScriptBaseUrl}/recognize');
      debugPrint('📡 Content-Type: $contentType | Lang: $language');

      final response = await dio.post(
        '${AppConstants.myScriptBaseUrl}/recognize',
        data: body,
        options: Options(
          headers: {
            'applicationKey': AppConstants.myScriptApplicationKey,
            'hmac': hmac,
            'Content-Type': 'application/json',
            'Accept': 'application/vnd.myscript.jiix,application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final label = data['label'] as String? ?? '';
        debugPrint('✅ Recognized: $label');
        return label;
      }

      throw ServerException('HTTP ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.type} | ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      throw NetworkException(
        'Network error: ${e.message}',
      );
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ Error: $e\n📍 $stack');
      throw RecognitionException(
        'Unexpected: $e',
      );
    }
  }
}
