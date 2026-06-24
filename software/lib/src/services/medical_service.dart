// lib/src/services/medical_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_case.dart';
import '../config/constants.dart';

class MedicalService {
  // ───── Medical Cases ─────

  static final List<MedicalCase> _mockCases = [
    MedicalCase(
      id: 'doc-1',
      caseId: 'CASE-2026-047',
      modality: 'Brain MRI',
      uploadedBy: 'user123',
      status: AppConstants.caseStatusPending,
      imageUrl: '',
      radiologistValidated: false,
      doctorApproved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MedicalCase(
      id: 'doc-2',
      caseId: 'CASE-2026-046',
      modality: 'Spine MRI',
      uploadedBy: 'user123',
      status: AppConstants.caseStatusInReview,
      imageUrl: '',
      radiologistValidated: true,
      doctorApproved: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    MedicalCase(
      id: 'doc-3',
      caseId: 'CASE-2026-045',
      modality: 'Chest X-Ray',
      uploadedBy: 'user123',
      status: AppConstants.caseStatusValidated,
      imageUrl: '',
      radiologistValidated: true,
      doctorApproved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MedicalCase(
      id: 'doc-4',
      caseId: 'CASE-2026-044',
      modality: 'CT Scan',
      uploadedBy: 'user123',
      status: AppConstants.caseStatusCompleted,
      imageUrl: '',
      radiologistValidated: true,
      doctorApproved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static bool _initialized = false;

  Future<void> _loadFromPrefs() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('medical_cases');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _mockCases.clear();
      for (var d in decoded) {
        _mockCases.add(MedicalCase.fromJson(d));
      }
    }
    _initialized = true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _mockCases.map((e) => e.toJson()).toList();
    await prefs.setString('medical_cases', jsonEncode(data));
  }

  Stream<List<MedicalCase>> casesStream({String? uploadedBy, String? status}) async* {
    await _loadFromPrefs();
    List<MedicalCase> filtered = List.from(_mockCases);
    if (status != null && status != 'all') {
      filtered = filtered.where((c) => c.status == status).toList();
    }
    yield filtered;
  }

  Future<List<MedicalCase>> getCases({String? uploadedBy, String? status}) async {
    await _loadFromPrefs();
    List<MedicalCase> filtered = List.from(_mockCases);
    if (status != null && status != 'all') {
      filtered = filtered.where((c) => c.status == status).toList();
    }
    return filtered;
  }

  /// Get single case by ID
  Future<MedicalCase?> getCase(String caseId) async {
    await _loadFromPrefs();
    try {
      return _mockCases.firstWhere((c) => c.id == caseId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new anonymized medical case
  Future<String?> createCase({
    required String modality,
    required String uploadedBy,
    String? imageUrl,
    String? aiPrediction,
    double? aiConfidence,
    String? aiSeverity,
    String? aiModelUsed,
    String? heatmapUrl,
    String? segmentationMaskUrl,
  }) async {
    await _loadFromPrefs();
    final year = DateTime.now().year;
    final count = _mockCases.length + 1;
    final caseId = 'CASE-$year-${count.toString().padLeft(3, '0')}';

    _mockCases.insert(0, MedicalCase(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      caseId: caseId,
      modality: modality,
      uploadedBy: uploadedBy,
      status: AppConstants.caseStatusPending,
      imageUrl: imageUrl ?? '',
      aiPrediction: aiPrediction,
      aiConfidence: aiConfidence,
      aiSeverity: aiSeverity,
      aiModelUsed: aiModelUsed,
      heatmapUrl: heatmapUrl,
      segmentationMaskUrl: segmentationMaskUrl,
      radiologistValidated: false,
      doctorApproved: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await _saveToPrefs();
    return caseId;
  }

  /// Update case status
  Future<bool> updateCaseStatus(String docId, String newStatus) async {
    await _loadFromPrefs();
    final index = _mockCases.indexWhere((c) => c.id == docId || c.caseId == docId);
    if (index == -1) return false;
    final oldCase = _mockCases[index];
    _mockCases[index] = MedicalCase(
      id: oldCase.id,
      caseId: oldCase.caseId,
      modality: oldCase.modality,
      uploadedBy: oldCase.uploadedBy,
      assignedRadiologistId: oldCase.assignedRadiologistId,
      assignedDoctorId: oldCase.assignedDoctorId,
      aiPrediction: oldCase.aiPrediction,
      aiConfidence: oldCase.aiConfidence,
      aiSeverity: oldCase.aiSeverity,
      aiModelUsed: oldCase.aiModelUsed,
      segmentationMaskUrl: oldCase.segmentationMaskUrl,
      heatmapUrl: oldCase.heatmapUrl,
      imageUrl: oldCase.imageUrl,
      status: newStatus,
      clinicalNotes: oldCase.clinicalNotes,
      radiologistValidated: oldCase.radiologistValidated,
      doctorApproved: oldCase.doctorApproved,
      createdAt: oldCase.createdAt,
      updatedAt: DateTime.now(),
    );
    await _saveToPrefs();
    return true;
  }

  /// Doctor validates/approves a case
  Future<bool> doctorApprove(String docId, String notes) async {
    await _loadFromPrefs();
    final index = _mockCases.indexWhere((c) => c.id == docId || c.caseId == docId);
    if (index == -1) return false;
    final oldCase = _mockCases[index];
    _mockCases[index] = MedicalCase(
      id: oldCase.id,
      caseId: oldCase.caseId,
      modality: oldCase.modality,
      uploadedBy: oldCase.uploadedBy,
      assignedRadiologistId: oldCase.assignedRadiologistId,
      assignedDoctorId: oldCase.assignedDoctorId,
      aiPrediction: oldCase.aiPrediction,
      aiConfidence: oldCase.aiConfidence,
      aiSeverity: oldCase.aiSeverity,
      aiModelUsed: oldCase.aiModelUsed,
      segmentationMaskUrl: oldCase.segmentationMaskUrl,
      heatmapUrl: oldCase.heatmapUrl,
      imageUrl: oldCase.imageUrl,
      status: oldCase.status,
      clinicalNotes: oldCase.clinicalNotes == null ? notes : '${oldCase.clinicalNotes}\n$notes',
      radiologistValidated: oldCase.radiologistValidated,
      doctorApproved: true,
      createdAt: oldCase.createdAt,
      updatedAt: DateTime.now(),
    );
    await _saveToPrefs();
    return true;
  }

  /// Radiologist validates annotation
  Future<bool> radiologistValidate(String docId) async {
    await _loadFromPrefs();
    final index = _mockCases.indexWhere((c) => c.id == docId || c.caseId == docId);
    if (index == -1) return false;
    final oldCase = _mockCases[index];
    _mockCases[index] = MedicalCase(
      id: oldCase.id,
      caseId: oldCase.caseId,
      modality: oldCase.modality,
      uploadedBy: oldCase.uploadedBy,
      assignedRadiologistId: oldCase.assignedRadiologistId,
      assignedDoctorId: oldCase.assignedDoctorId,
      aiPrediction: oldCase.aiPrediction,
      aiConfidence: oldCase.aiConfidence,
      aiSeverity: oldCase.aiSeverity,
      aiModelUsed: oldCase.aiModelUsed,
      segmentationMaskUrl: oldCase.segmentationMaskUrl,
      heatmapUrl: oldCase.heatmapUrl,
      imageUrl: oldCase.imageUrl,
      status: oldCase.status,
      clinicalNotes: oldCase.clinicalNotes,
      radiologistValidated: true,
      doctorApproved: oldCase.doctorApproved,
      createdAt: oldCase.createdAt,
      updatedAt: DateTime.now(),
    );
    await _saveToPrefs();
    return true;
  }

  // ───── Experiments (Researcher) ─────

  Stream<List<AIExperiment>> experimentsStream(String researcherId) async* {
    yield [
      AIExperiment(
        id: 'doc-exp-1',
        experimentId: 'EXP-2026-001',
        modelName: 'DERNet-v2.1',
        modality: 'Brain MRI',
        createdBy: researcherId,
        status: 'running',
        accuracy: 94.2,
        loss: 0.12,
        precision: 0.93,
        recall: 0.95,
        f1Score: 0.94,
        epochsTotal: 100,
        epochsCurrent: 67,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      AIExperiment(
        id: 'doc-exp-2',
        experimentId: 'EXP-2026-002',
        modelName: 'SpineNet-101',
        modality: 'Spine MRI',
        createdBy: researcherId,
        status: 'completed',
        accuracy: 88.7,
        loss: 0.21,
        precision: 0.87,
        recall: 0.89,
        f1Score: 0.88,
        epochsTotal: 150,
        epochsCurrent: 150,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<bool> createExperiment({
    required String modelName,
    required String modality,
    required String createdBy,
    required int epochs,
  }) async {
    return true;
  }
}
