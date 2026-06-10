// lib/src/models/medical_case.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalCase {
  final String id;
  final String caseId; // e.g., CASE-2026-001
  final String modality; // Brain MRI, Spine MRI, Chest X-Ray, CT Scan
  final String uploadedBy; // UID of doctor/radiologist
  final String? assignedRadiologistId;
  final String? assignedDoctorId;

  // AI Analysis
  final String? aiPrediction;
  final double? aiConfidence;
  final String? aiSeverity;
  final String? aiModelUsed;
  final String? segmentationMaskUrl;
  final String? heatmapUrl;
  final String? imageUrl;

  // Status
  final String status; // pending, in_review, validated, completed
  final String? clinicalNotes;
  final bool radiologistValidated;
  final bool doctorApproved;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalCase({
    required this.id,
    required this.caseId,
    required this.modality,
    required this.uploadedBy,
    this.assignedRadiologistId,
    this.assignedDoctorId,
    this.aiPrediction,
    this.aiConfidence,
    this.aiSeverity,
    this.aiModelUsed,
    this.segmentationMaskUrl,
    this.heatmapUrl,
    this.imageUrl,
    this.status = 'pending',
    this.clinicalNotes,
    this.radiologistValidated = false,
    this.doctorApproved = false,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalCase.fromMap(String id, Map<String, dynamic> data) {
    return MedicalCase(
      id: id,
      caseId: data['caseId'] ?? '',
      modality: data['modality'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      assignedRadiologistId: data['assignedRadiologistId'],
      assignedDoctorId: data['assignedDoctorId'],
      aiPrediction: data['aiPrediction'],
      aiConfidence: (data['aiConfidence'] as num?)?.toDouble(),
      aiSeverity: data['aiSeverity'],
      aiModelUsed: data['aiModelUsed'],
      segmentationMaskUrl: data['segmentationMaskUrl'],
      heatmapUrl: data['heatmapUrl'],
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'pending',
      clinicalNotes: data['clinicalNotes'],
      radiologistValidated: (data['radiologistValidated'] as bool?) ?? false,
      doctorApproved: (data['doctorApproved'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'modality': modality,
      'uploadedBy': uploadedBy,
      if (assignedRadiologistId != null) 'assignedRadiologistId': assignedRadiologistId,
      if (assignedDoctorId != null) 'assignedDoctorId': assignedDoctorId,
      if (aiPrediction != null) 'aiPrediction': aiPrediction,
      if (aiConfidence != null) 'aiConfidence': aiConfidence,
      if (aiSeverity != null) 'aiSeverity': aiSeverity,
      if (aiModelUsed != null) 'aiModelUsed': aiModelUsed,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
      'radiologistValidated': radiologistValidated,
      'doctorApproved': doctorApproved,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AIExperiment {
  final String id;
  final String experimentId; // EXP-2026-001
  final String modelName;
  final String modality;
  final double accuracy;
  final double loss;
  final double precision;
  final double recall;
  final double f1Score;
  final String status; // running, completed, paused, failed
  final int epochsTotal;
  final int epochsCurrent;
  final String createdBy; // researcher UID
  final DateTime? createdAt;

  const AIExperiment({
    required this.id,
    required this.experimentId,
    required this.modelName,
    required this.modality,
    required this.accuracy,
    required this.loss,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.status,
    required this.epochsTotal,
    required this.epochsCurrent,
    required this.createdBy,
    this.createdAt,
  });

  factory AIExperiment.fromMap(String id, Map<String, dynamic> data) {
    return AIExperiment(
      id: id,
      experimentId: data['experimentId'] ?? '',
      modelName: data['modelName'] ?? '',
      modality: data['modality'] ?? '',
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
      loss: (data['loss'] as num?)?.toDouble() ?? 0.0,
      precision: (data['precision'] as num?)?.toDouble() ?? 0.0,
      recall: (data['recall'] as num?)?.toDouble() ?? 0.0,
      f1Score: (data['f1Score'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      epochsTotal: (data['epochsTotal'] as int?) ?? 0,
      epochsCurrent: (data['epochsCurrent'] as int?) ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
