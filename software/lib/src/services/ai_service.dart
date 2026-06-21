// lib/src/services/ai_service.dart
// NeuroVision AI — Client service for the FastAPI inference server.
// Sends images to the backend and parses AI predictions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'server_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';

class AIResult {
  final String prediction;
  final double confidence;
  final String modality;
  final String modelUsed;
  final Map<String, double> allProbabilities;
  final String? heatmapBase64;
  final String? segmentationMaskBase64;
  final String severity;
  final String message;
  final String? vertebralLevel;
  final double? lesionCoveragePct;
  final int? lesionVoxels;

  const AIResult({
    required this.prediction,
    required this.confidence,
    required this.modality,
    required this.modelUsed,
    required this.allProbabilities,
    this.heatmapBase64,
    this.segmentationMaskBase64,
    required this.severity,
    required this.message,
    this.vertebralLevel,
    this.lesionCoveragePct,
    this.lesionVoxels,
  });

  factory AIResult.fromJson(Map<String, dynamic> json) {
    final probs = <String, double>{};
    if (json['all_probabilities'] != null) {
      (json['all_probabilities'] as Map<String, dynamic>).forEach((k, v) {
        probs[k] = (v as num).toDouble();
      });
    }
    return AIResult(
      prediction: json['prediction'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      modality: json['modality'] ?? '',
      modelUsed: json['model_used'] ?? '',
      allProbabilities: probs,
      heatmapBase64: json['heatmap_base64'],
      segmentationMaskBase64: json['segmentation_mask_base64'],
      severity: json['severity'] ?? 'Unknown',
      message: json['message'] ?? '',
      vertebralLevel: json['vertebral_level'],
      lesionCoveragePct: (json['lesion_coverage_pct'] as num?)?.toDouble(),
      lesionVoxels: (json['lesion_voxels'] as num?)?.toInt(),
    );
  }

  Color get severityColor => switch (severity) {
    'High' || 'Critical' => const Color(0xFFFF4757),
    'Medium' => const Color(0xFFFFB347),
    'None' => const Color(0xFF2ED573),
    _ => const Color(0xFF1E90FF),
  };
}

// ignore: avoid_classes_with_only_static_members
class AIService {
  // ──────────────────────────────────────────────────────────────────────────
  // Server base URL — resolved at runtime from ServerConfig (SharedPreferences).
  //   • Web (Chrome/browser) → always localhost:8000 (same machine as server)
  //   • Android / other     → IP stored via the in-app Server Settings dialog
  //
  // To change the IP without rebuilding: open the app → tap the Wi-Fi icon
  // in the top-right corner → enter the new IP → Save.
  // ──────────────────────────────────────────────────────────────────────────
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    return ServerConfig.instance.baseUrl;
  }

  /// Total wall-clock budget for upload + AI inference + response download.
  /// Heavy models (SegResNet, YOLO) can take 60-90 s on CPU — 2 min is safe.
  static const Duration _timeout = Duration(minutes: 2);

  /// Socket-level connection timeout — fails fast when the PC is unreachable
  /// (wrong IP / Android on a different subnet / PC firewall blocking).
  static const Duration _connectTimeout = Duration(seconds: 15);
  // ── Brain MRI Analysis ────────────────────────────────────────────────────

  /// Analyze a brain MRI image file.
  /// [model] options: 'DERNet' | 'SegResNet' | 'AttentionUNet'
  static Future<AIResult> analyzeBrainMRI(
    Uint8List imageBytes, {
    String model = 'DERNet',
    String filename = 'brain_mri.png',
  }) async {
    return _uploadAndAnalyze(
      endpoint: '$_baseUrl/brain/analyze?model=$model',
      imageBytes: imageBytes,
      filename: filename,
    );
  }

  /// Run brain MRI segmentation (returns segmentation mask + classification).
  static Future<AIResult> segmentBrainMRI(
    Uint8List imageBytes, {
    String model = 'AttentionUNet',
  }) async {
    return _uploadAndAnalyze(
      endpoint: '$_baseUrl/brain/segment?model=$model',
      imageBytes: imageBytes,
      filename: 'brain_mri.png',
    );
  }

  // ── Spine MRI Analysis ────────────────────────────────────────────────────

  /// Analyze a spine MRI image file.
  /// [model] options: 'EfficientNet' | 'DenseNet' | 'ResNet50'
  static Future<AIResult> analyzeSpineMRI(
    Uint8List imageBytes, {
    String model = 'EfficientNet',
    String filename = 'spine_mri.png',
  }) async {
    return _uploadAndAnalyze(
      endpoint: '$_baseUrl/spine/analyze?model=$model',
      imageBytes: imageBytes,
      filename: filename,
    );
  }

  // ── Chest X-Ray Analysis ──────────────────────────────────────────────────

  /// Analyze a chest X-ray image.
  static Future<AIResult> analyzeChestXRay(
    Uint8List imageBytes, {
    String filename = 'chest_xray.png',
  }) async {
    return _uploadAndAnalyze(
      endpoint: '$_baseUrl/chest/analyze',
      imageBytes: imageBytes,
      filename: filename,
    );
  }

  // ── Heart Echo Analysis ──────────────────────────────────────────────────

  /// Analyze a heart echo image.
  static Future<AIResult> analyzeHeartEcho(
    Uint8List imageBytes, {
    String model = 'CatBoost-Echo',
    String filename = 'heart_echo.png',
  }) async {
    return _uploadAndAnalyze(
      endpoint: '$_baseUrl/heart/analyze?model=$model',
      imageBytes: imageBytes,
      filename: filename,
    );
  }

  // ── Auto-route by Modality ────────────────────────────────────────────────

  /// Automatically select the right pipeline based on modality string.
  static Future<AIResult> analyzeByModality(
    Uint8List imageBytes,
    String modality, {
    String? preferredModel,
  }) async {
    switch (modality) {
      case 'Brain MRI':
        return analyzeBrainMRI(imageBytes, model: preferredModel ?? 'DERNet');
      case 'Spine MRI':
        return analyzeSpineMRI(imageBytes, model: preferredModel ?? 'EfficientNet');
      case 'Chest X-Ray':
        return analyzeChestXRay(imageBytes);
      case 'Heart (Echo)':
      case 'Heart':
        return analyzeHeartEcho(imageBytes, model: preferredModel ?? 'CatBoost-Echo');
      case 'CT Scan':
        // CT routed to brain pipeline for now
        return analyzeBrainMRI(imageBytes, model: preferredModel ?? 'DERNet');
      default:
        throw Exception('Unknown modality: $modality');
    }
  }

  // ── Health Check ──────────────────────────────────────────────────────────

  /// Check if the inference server is running and models are loaded.
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'statusCode': response.statusCode};
    } catch (e) {
      return {'status': 'unreachable', 'error': e.toString()};
    }
  }

  // ── Private Helper ────────────────────────────────────────────────────────

  /// Build an [http.Client] with socket-level timeouts for Android LAN calls.
  /// On Web, dart:io is unavailable so a plain [http.Client] is returned.
  static http.Client _buildClient() {
    if (kIsWeb) return http.Client();
    final ioClient = HttpClient()
      // Fail fast if the PC can't be reached (wrong IP / different subnet).
      ..connectionTimeout = _connectTimeout
      // Keep the TCP socket alive during long server-side AI inference.
      ..idleTimeout = _timeout;
    return IOClient(ioClient);
  }

  static Future<AIResult> _uploadAndAnalyze({
    required String endpoint,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    // Wrap the ENTIRE round-trip (upload + server inference + response body)
    // in one timeout so Android never hangs silently past _timeout.
    return Future(() async {
      final client = _buildClient();
      try {
        final uri = Uri.parse(endpoint);
        final request = http.MultipartRequest('POST', uri)
          ..headers['Accept'] = 'application/json';

        final isPng = filename.toLowerCase().endsWith('.png');
        final mediaType =
            isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: mediaType,
        ));

        // send() through our IOClient (respects socket-level timeouts on Android)
        final streamedResponse = await client.send(request);
        // fromStream() waits for the full response body — this is where
        // server-side inference time is spent; it is now inside the outer timeout.
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return AIResult.fromJson(json);
        } else {
          final error = jsonDecode(response.body);
          throw Exception(
              'Server error ${response.statusCode}: ${error['detail'] ?? error}');
        }
      } on SocketException catch (e) {
        throw Exception(
            'Network error – cannot reach "$_baseUrl". '
            'Ensure your Android is on the same Wi-Fi as the PC. '
            'Details: $e');
      } on http.ClientException catch (e) {
        throw Exception(
            'Cannot connect to AI server at "$_baseUrl". '
            'Ensure the FastAPI server is running. Details: $e');
      } finally {
        client.close();
      }
    }).timeout(
      _timeout,
      onTimeout: () => throw Exception(
          'AI analysis timed out after ${_timeout.inMinutes} min. '
          'The server may be overloaded or the network is very slow.'),
    );
  }
}
