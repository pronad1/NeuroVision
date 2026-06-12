// lib/src/providers/analysis_provider.dart
// Central state for the medical image upload & AI analysis flow.
// Manages modality selection, model choice, image upload, and AI results.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

// ─── Modality Enum ────────────────────────────────────────────────────────────

enum MedicalModality {
  brain,
  spine,
  chest,
  heart;

  String get displayName => switch (this) {
        brain => 'Brain MRI',
        spine => 'Spine MRI',
        chest => 'Chest X-Ray',
        heart => 'Heart (Echo)',
      };

  String get apiModality => switch (this) {
        brain => 'Brain MRI',
        spine => 'Spine MRI',
        chest => 'Chest X-Ray',
        heart => 'Heart',
      };

  bool get isAvailable => this == MedicalModality.brain || this == MedicalModality.spine;

  String get unavailableReason => switch (this) {
        chest => 'Keras .h5 integration in progress',
        heart => 'CatBoost model integration coming soon',
        _ => '',
      };

  IconData get icon => switch (this) {
        brain => Icons.psychology_rounded,
        spine => Icons.accessibility_new_rounded,
        chest => Icons.favorite_border_rounded,
        heart => Icons.monitor_heart_rounded,
      };

  Color get color => switch (this) {
        brain => const Color(0xFF9C7EE8),
        spine => const Color(0xFF26A1FF),
        chest => const Color(0xFFFF6B9D),
        heart => const Color(0xFFFF4757),
      };

  List<ModelOption> get availableModels => switch (this) {
        brain => [
            ModelOption(
              id: 'DERNet',
              name: 'DERNet',
              description: 'LSCBlock + BiMambaSim + BAGF gated fusion',
              metric: 'Val Dice: 0.817',
              isRecommended: true,
            ),
            ModelOption(
              id: 'SegResNet',
              name: 'SegResNet',
              description: 'MONAI SegResNet with 3-flip TTA',
              metric: 'Test Dice: 0.782',
              isRecommended: false,
            ),
            ModelOption(
              id: 'AttentionUNet',
              name: 'AttentionUNet',
              description: 'MONAI AttentionUnet with attention gates',
              metric: 'Val Dice: 0.779',
              isRecommended: false,
            ),
          ],
        spine => [
            ModelOption(
              id: 'EfficientNet',
              name: 'EfficientNet',
              description: 'EfficientNet-B4 fine-tuned on VinDr-SpineXR',
              metric: 'AUC: 0.94',
              isRecommended: true,
            ),
            ModelOption(
              id: 'DenseNet',
              name: 'DenseNet',
              description: 'DenseNet-121 with global average pooling',
              metric: 'AUC: 0.91',
              isRecommended: false,
            ),
            ModelOption(
              id: 'ResNet50',
              name: 'ResNet50',
              description: 'ResNet-50 baseline with transfer learning',
              metric: 'AUC: 0.89',
              isRecommended: false,
            ),
          ],
        _ => [],
      };
}

// ─── Model Option ──────────────────────────────────────────────────────────────

class ModelOption {
  final String id;
  final String name;
  final String description;
  final String metric;
  final bool isRecommended;

  const ModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.metric,
    required this.isRecommended,
  });
}

// ─── Analysis Step ─────────────────────────────────────────────────────────────

enum AnalysisStep { selectModality, selectModel, uploadImage, running, results, error }

// ─── Analysis Provider ─────────────────────────────────────────────────────────

class AnalysisProvider extends ChangeNotifier {
  MedicalModality? _selectedModality;
  ModelOption? _selectedModel;
  Uint8List? _imageBytes;
  String? _imageFileName;
  AIResult? _result;
  String? _errorMessage;
  AnalysisStep _step = AnalysisStep.selectModality;
  bool _isAnalyzing = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  MedicalModality? get selectedModality => _selectedModality;
  ModelOption? get selectedModel => _selectedModel;
  Uint8List? get imageBytes => _imageBytes;
  String? get imageFileName => _imageFileName;
  AIResult? get result => _result;
  String? get errorMessage => _errorMessage;
  AnalysisStep get step => _step;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasResult => _result != null;

  // ── Actions ────────────────────────────────────────────────────────────────

  void selectModality(MedicalModality modality) {
    _selectedModality = modality;
    _selectedModel = modality.availableModels.isNotEmpty
        ? modality.availableModels.first
        : null;
    _step = AnalysisStep.uploadImage;
    notifyListeners();
  }

  void selectModel(ModelOption model) {
    _selectedModel = model;
    _step = AnalysisStep.uploadImage;
    notifyListeners();
  }

  void setImageBytes(Uint8List bytes, String fileName) {
    _imageBytes = bytes;
    _imageFileName = fileName;
    notifyListeners();
  }

  /// Pick image from gallery (mobile) or file system.
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setImageBytes(bytes, pickedFile.name);
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<void> runAnalysis() async {
    if (_imageBytes == null || _selectedModality == null) return;

    _isAnalyzing = true;
    _step = AnalysisStep.running;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      final AIResult result;
      final modality = _selectedModality!;
      final modelId = _selectedModel?.id;

      switch (modality) {
        case MedicalModality.brain:
          result = await AIService.analyzeBrainMRI(
            _imageBytes!,
            model: modelId ?? 'DERNet',
            filename: _imageFileName ?? 'brain_mri.png',
          );
        case MedicalModality.spine:
          result = await AIService.analyzeSpineMRI(
            _imageBytes!,
            model: modelId ?? 'EfficientNet',
            filename: _imageFileName ?? 'spine_mri.png',
          );
        case MedicalModality.chest:
          result = await AIService.analyzeChestXRay(
            _imageBytes!,
            filename: _imageFileName ?? 'chest_xray.png',
          );
        case MedicalModality.heart:
          throw Exception('Heart model not yet available.');
      }

      _result = result;
      _step = AnalysisStep.results;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _step = AnalysisStep.error;
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  void goBack() {
    switch (_step) {
      case AnalysisStep.selectModality:
        break;
      case AnalysisStep.selectModel:
        _step = AnalysisStep.selectModality;
        _selectedModality = null;
        _selectedModel = null;
      case AnalysisStep.uploadImage:
        _step = AnalysisStep.selectModality;
        _selectedModality = null;
        _selectedModel = null;
        _imageBytes = null;
        _imageFileName = null;
      case AnalysisStep.running:
        break; // Can't go back while running
      case AnalysisStep.results:
      case AnalysisStep.error:
        _step = AnalysisStep.uploadImage;
        _result = null;
        _errorMessage = null;
    }
    notifyListeners();
  }

  void resetAll() {
    _selectedModality = null;
    _selectedModel = null;
    _imageBytes = null;
    _imageFileName = null;
    _result = null;
    _errorMessage = null;
    _step = AnalysisStep.selectModality;
    _isAnalyzing = false;
    notifyListeners();
  }

  void clearImageOnly() {
    _imageBytes = null;
    _imageFileName = null;
    notifyListeners();
  }
}
