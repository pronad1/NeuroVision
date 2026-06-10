// lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NVUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'doctor', 'radiologist', 'researcher'
  final String? institution;
  final String? specialization;
  final String? photoUrl;
  final bool approved;
  final bool isAdmin;
  final DateTime? createdAt;

  const NVUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.institution,
    this.specialization,
    this.photoUrl,
    this.approved = false,
    this.isAdmin = false,
    this.createdAt,
  });

  factory NVUser.fromMap(String uid, Map<String, dynamic> data) {
    return NVUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'doctor',
      institution: data['institution'],
      specialization: data['specialization'],
      photoUrl: data['photoUrl'],
      approved: (data['approved'] as bool?) ?? false,
      isAdmin: (data['isAdmin'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (institution != null) 'institution': institution,
      if (specialization != null) 'specialization': specialization,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'approved': approved,
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isDoctor => role == 'doctor';
  bool get isRadiologist => role == 'radiologist';
  bool get isResearcher => role == 'researcher';

  String get roleDisplayName {
    switch (role) {
      case 'doctor': return 'Doctor';
      case 'radiologist': return 'Radiologist';
      case 'researcher': return 'Researcher';
      default: return role;
    }
  }

  NVUser copyWith({
    String? name,
    String? institution,
    String? specialization,
    String? photoUrl,
    bool? approved,
  }) {
    return NVUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      institution: institution ?? this.institution,
      specialization: specialization ?? this.specialization,
      photoUrl: photoUrl ?? this.photoUrl,
      approved: approved ?? this.approved,
      isAdmin: isAdmin,
      createdAt: createdAt,
    );
  }
}
