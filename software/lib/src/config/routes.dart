// lib/src/config/routes.dart
import 'package:flutter/material.dart';

// Auth
import '../ui/screens/splash_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';

// Shared
import '../ui/screens/shared/profile_screen.dart';

// Doctor Dashboards
import '../ui/screens/dashboard/doctor/doctor_dashboard.dart';
import '../ui/screens/dashboard/doctor/medical_cases_screen.dart';
import '../ui/screens/dashboard/doctor/ai_diagnosis_screen.dart';
import '../ui/screens/dashboard/doctor/segmentation_screen.dart';
import '../ui/screens/dashboard/doctor/clinical_notes_screen.dart';
import '../ui/screens/dashboard/doctor/heatmaps_screen.dart';
import '../ui/screens/dashboard/doctor/comparative_analysis_screen.dart';

// Radiologist Dashboards
import '../ui/screens/dashboard/radiologist/radiologist_dashboard.dart';
import '../ui/screens/dashboard/radiologist/annotation_screen.dart';
import '../ui/screens/dashboard/radiologist/dicom_viewer_screen.dart';
import '../ui/screens/dashboard/radiologist/lesion_localization_screen.dart';
import '../ui/screens/dashboard/radiologist/segmentation_review_screen.dart';
import '../ui/screens/dashboard/radiologist/explainability_screen.dart';

// Researcher Dashboards
import '../ui/screens/dashboard/researcher/researcher_dashboard.dart';
import '../ui/screens/dashboard/researcher/experiment_tracking_screen.dart';
import '../ui/screens/dashboard/researcher/model_monitoring_screen.dart';
import '../ui/screens/dashboard/researcher/metrics_screen.dart';
import '../ui/screens/dashboard/researcher/confusion_matrix_screen.dart';
import '../ui/screens/dashboard/researcher/dataset_management_screen.dart';
import '../ui/screens/dashboard/researcher/gpu_monitor_screen.dart';

import 'constants.dart';


class Routes {
  // ── Auth ──
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // ── Shared ──
  static const String profile = '/profile';

  // ── Doctor ──
  static const String doctorDashboard = '/dashboard/doctor';
  static const String doctorCases = '/dashboard/doctor/cases';
  static const String doctorAIDiagnosis = '/dashboard/doctor/ai-diagnosis';
  static const String doctorSegmentation = '/dashboard/doctor/segmentation';
  static const String doctorHeatmaps = '/dashboard/doctor/heatmaps';
  static const String doctorComparative = '/dashboard/doctor/comparative';
  static const String doctorNotes = '/dashboard/doctor/notes';

  // ── Radiologist ──
  static const String radiologistDashboard = '/dashboard/radiologist';
  static const String radiologistDicom = '/dashboard/radiologist/dicom';
  static const String radiologistAnnotations = '/dashboard/radiologist/annotations';
  static const String radiologistLesions = '/dashboard/radiologist/lesions';
  static const String radiologistSegmentation = '/dashboard/radiologist/segmentation';
  static const String radiologistExplainability = '/dashboard/radiologist/explainability';

  // ── Researcher ──
  static const String researcherDashboard = '/dashboard/researcher';
  static const String researcherModels = '/dashboard/researcher/models';
  static const String researcherMetrics = '/dashboard/researcher/metrics';
  static const String researcherConfusion = '/dashboard/researcher/confusion';
  static const String researcherExperiments = '/dashboard/researcher/experiments';
  static const String researcherDatasets = '/dashboard/researcher/datasets';
  static const String researcherGpu = '/dashboard/researcher/gpu';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ── Auth Routes ──
      case splash:
        return _fade(const SplashScreen());
      case login:
        return _fade(const LoginScreen());
      case signup:
        return _fade(const SignUpScreen());
      case forgotPassword:
        return _slide(const ForgotPasswordScreen());

      // ── Shared ──
      case profile:
        return _fade(const ProfileScreen());

      // ── Doctor Routes ──
      case doctorDashboard:
        return _fade(const DoctorDashboard());
      case doctorCases:
        return _fade(const MedicalCasesScreen());
      case doctorAIDiagnosis:
        return _fade(const AIDiagnosisScreen());
      case doctorSegmentation:
        return _fade(const SegmentationScreen());
      case doctorHeatmaps:
        return _fade(const HeatmapsScreen());
      case doctorComparative:
        return _fade(const ComparativeAnalysisScreen());
      case doctorNotes:
        return _fade(const ClinicalNotesScreen());

      // ── Radiologist Routes ──
      case radiologistDashboard:
        return _fade(const RadiologistDashboard());
      case radiologistAnnotations:
        return _fade(const AnnotationScreen());
      case radiologistDicom:
        return _fade(const DicomViewerScreen());
      case radiologistLesions:
        return _fade(const LesionLocalizationScreen());
      case radiologistSegmentation:
        return _fade(const SegmentationReviewScreen());
      case radiologistExplainability:
        return _fade(const ExplainabilityScreen());

      // ── Researcher Routes ──
      case researcherDashboard:
        return _fade(const ResearcherDashboard());
      case researcherModels:
        return _fade(const ModelMonitoringScreen());
      case researcherExperiments:
        return _fade(const ExperimentTrackingScreen());
      case researcherMetrics:
        return _fade(const MetricsScreen());
      case researcherConfusion:
        return _fade(const ConfusionMatrixScreen());
      case researcherDatasets:
        return _fade(const DatasetManagementScreen());
      case researcherGpu:
        return _fade(const GpuMonitorScreen());

      default:
        return _fade(const SplashScreen());
    }
  }

  static Route<dynamic> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static Route<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
