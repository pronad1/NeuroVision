// lib/src/services/medical_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medical_case.dart';
import '../config/constants.dart';

class MedicalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───── Medical Cases ─────

  /// Stream of all cases (sorted by createdAt desc)
  Stream<List<MedicalCase>> casesStream({String? uploadedBy, String? status}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.casesCollection)
        .orderBy('createdAt', descending: true);

    if (uploadedBy != null) query = query.where('uploadedBy', isEqualTo: uploadedBy);
    if (status != null) query = query.where('status', isEqualTo: status);

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => MedicalCase.fromMap(d.id, d.data())).toList());
  }

  /// Get single case by ID
  Future<MedicalCase?> getCase(String caseId) async {
    try {
      final doc = await _db.collection(AppConstants.casesCollection).doc(caseId).get();
      if (!doc.exists) return null;
      return MedicalCase.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error getting case: $e');
      return null;
    }
  }

  /// Create a new anonymized medical case
  Future<String?> createCase({
    required String modality,
    required String uploadedBy,
    String? imageUrl,
  }) async {
    try {
      // Generate case ID
      final year = DateTime.now().year;
      final count = await _db.collection(AppConstants.casesCollection).count().get();
      final caseNumber = (count.count ?? 0) + 1;
      final caseId = 'CASE-$year-${caseNumber.toString().padLeft(3, '0')}';

      await _db.collection(AppConstants.casesCollection).add({
        'caseId': caseId,
        'modality': modality,
        'uploadedBy': uploadedBy,
        'status': AppConstants.caseStatusPending,
        'imageUrl': imageUrl ?? '',
        'radiologistValidated': false,
        'doctorApproved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return caseId;
    } catch (e) {
      debugPrint('Error creating case: $e');
      return null;
    }
  }

  /// Update case status
  Future<bool> updateCaseStatus(String docId, String newStatus) async {
    try {
      await _db.collection(AppConstants.casesCollection).doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating case: $e');
      return false;
    }
  }

  /// Doctor validates/approves a case
  Future<bool> doctorApprove(String docId, String notes) async {
    try {
      await _db.collection(AppConstants.casesCollection).doc(docId).update({
        'doctorApproved': true,
        'clinicalNotes': notes,
        'status': AppConstants.caseStatusValidated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error approving case: $e');
      return false;
    }
  }

  /// Radiologist validates annotation
  Future<bool> radiologistValidate(String docId) async {
    try {
      await _db.collection(AppConstants.casesCollection).doc(docId).update({
        'radiologistValidated': true,
        'status': AppConstants.caseStatusInReview,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error validating case: $e');
      return false;
    }
  }

  // ───── Experiments (Researcher) ─────

  Stream<List<AIExperiment>> experimentsStream(String researcherId) {
    return _db
        .collection(AppConstants.experimentsCollection)
        .where('createdBy', isEqualTo: researcherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AIExperiment.fromMap(d.id, d.data())).toList());
  }

  Future<bool> createExperiment({
    required String modelName,
    required String modality,
    required String createdBy,
    required int epochs,
  }) async {
    try {
      final year = DateTime.now().year;
      final count = await _db.collection(AppConstants.experimentsCollection).count().get();
      final expNum = (count.count ?? 0) + 1;
      final expId = 'EXP-$year-${expNum.toString().padLeft(3, '0')}';

      await _db.collection(AppConstants.experimentsCollection).add({
        'experimentId': expId,
        'modelName': modelName,
        'modality': modality,
        'createdBy': createdBy,
        'status': 'pending',
        'accuracy': 0.0,
        'loss': 0.0,
        'precision': 0.0,
        'recall': 0.0,
        'f1Score': 0.0,
        'epochsTotal': epochs,
        'epochsCurrent': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error creating experiment: $e');
      return false;
    }
  }
}
