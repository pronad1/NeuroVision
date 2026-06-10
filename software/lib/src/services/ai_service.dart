// lib/src/services/ai_service.dart
/// NeuroVision AI — Client service for the FastAPI inference server.
/// Sends images to the backend and parses AI predictions.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // Change this to your server IP when running on a real device.
  // Use 10.0.2.2 for Android emulator, localhost for desktop.
  // ──────────────────────────────────────────────────────────────────────────
  static const String _baseUrl = 'http://localhost:8000/api/v1';

  static const Duration _timeout = Duration(seconds: 60);

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

  static Future<AIResult> _uploadAndAnalyze({
    required String endpoint,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ));
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AIResult.fromJson(json);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Server error ${response.statusCode}: ${error['detail'] ?? error}');
      }
    } on SocketException {
      throw Exception('Cannot connect to AI server. Ensure the FastAPI server is running on $_baseUrl');
    } catch (e) {
      throw Exception('AI analysis failed: $e');
    }
  }
}
