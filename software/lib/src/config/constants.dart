// lib/src/config/constants.dart

class AppConstants {
  static const String appName = 'NeuroVision AI';
  static const String appTagline = 'AI-Powered Clinical Imaging Intelligence';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String casesCollection = 'medical_cases';
  static const String annotationsCollection = 'annotations';
  static const String experimentsCollection = 'experiments';
  static const String reportsCollection = 'reports';

  // User Roles
  static const String roleDoctor = 'doctor';
  static const String roleRadiologist = 'radiologist';
  static const String roleResearcher = 'researcher';

  // Case Status
  static const String caseStatusPending = 'pending';
  static const String caseStatusInReview = 'in_review';
  static const String caseStatusCompleted = 'completed';
  static const String caseStatusValidated = 'validated';

  // Imaging Modalities
  static const List<String> modalities = [
    'Brain MRI',
    'Spine MRI',
    'Chest X-Ray',
    'CT Scan',
  ];

  // AI Models
  static const List<String> brainModels = ['DERNet', 'SegResNet', 'Attention U-Net'];
  static const List<String> spineModels = ['DenseNet', 'EfficientNetV2', 'ResNet'];

  // Route names (kept here as aliases; main defs in routes.dart)
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeDoctorDashboard = '/dashboard/doctor';
  static const String routeRadiologistDashboard = '/dashboard/radiologist';
  static const String routeResearcherDashboard = '/dashboard/researcher';
}