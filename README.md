# NeuroVision AI

An Enterprise Multimodal Explainable Medical Diagnosis and Lesion Localization Ecosystem Using Deep Learning

## 🚀 Project Overview

**NeuroVision AI** is a cutting-edge medical imaging platform designed to assist doctors, radiologists, and researchers in diagnosing neurological conditions through advanced deep learning models. The platform integrates multiple AI pipelines for brain, spine, and chest imaging, providing lesion detection, segmentation, explainable AI (Grad-CAM), and research monitoring in a secure, enterprise-grade environment.

## ✨ Key Features

- **Multimodal Imaging Analysis**
  - 🧠 **Brain Intelligence**: Ischemic stroke analysis, lesion segmentation (DERNet, SegResNet)
  - 🦴 **Spine Intelligence**: Vertebral lesion detection and classification (DenseNet, EfficientNetV2)
  - 🫁 **Chest X-Ray**: Pneumonia and tuberculosis screening (future module)
  
- **Explainable AI Engine**
  - Visualizes AI reasoning through Grad-CAM heatmaps and activation maps
  - Builds trust by showing *why* the AI made a prediction
  - Enhances clinical validation and understanding
  
- **Research & Monitoring**
  - Tracks model performance and experiment metrics
  - Compares deep learning architectures (ResNet, DenseNet, etc.)
  - Visualizes training curves, confusion matrices, and validation results
  
- **Enterprise Clinical Workflow**
  - Secure, anonymized medical case management
  - Role-based access control (Doctor, Radiologist, Researcher)
  - Professional DICOM viewer and annotation tools
  - Integrated reporting and diagnostic workflows

## 🔧 Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.x |
| **State Management** | Provider |
| **Firebase** | Auth, Firestore, Storage |
| **Supabase** | Medical image storage |
| **Backend API** | FastAPI (upcoming) |
| **AI Models** | PyTorch, MONAI |
| **Imaging** | OpenCV |

## 📁 Project Structure

```bash
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── src/
│   ├── config/
│   │   ├── routes.dart         # Navigation
│   │   ├── theme.dart          # Design system
│   │   ├── constants.dart      # App constants
│   │   ├── api.dart            # API configuration
│   │   ├── notifications.dart  # Push notifications
│   │   └── splash.dart         # Splash screen logic
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   │
│   │   ├── home/
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── home_navigator.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── doctor_dashboard.dart
│   │   │   │   ├── radiologist_dashboard.dart
│   │   │   │   └── researcher_dashboard.dart
│   │   │   ├── ai_assist/
│   │   │   │   ├── ai_assist_hub.dart
│   │   │   │   ├── brain_analysis.dart
│   │   │   │   ├── spine_analysis.dart
│   │   │   │   └── chest_analysis.dart
│   │   │   └── ai_models/
│   │   │       ├── model_dashboard.dart
│   │   │       ├── research_monitoring.dart
│   │   │       ├── model_comparison.dart
│   │   │       ├── experiment_tracking.dart
│   │   │       └── model_training.dart
│   │   │
│   │   ├── cases/
│   │   │   ├── cases_dashboard.dart
│   │   │   ├── case_list.dart
│   │   │   ├── case_detail.dart
│   │   │   └── image_viewer.dart
│   │   │
│   │   ├── research/
│   │   │   ├── research_dashboard.dart
│   │   │   ├── experiment_setup.dart
│   │   │   ├── model_training.dart
│   │   │   └── research_reports.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── settings_screen.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── system_settings.dart
│   │   │   ├── notification_settings.dart
│   │   │   └── privacy_policy.dart
│   │   │
│   │   └── utilities/
│   │       ├── notifications.dart
│   │       ├── diagnostics.dart
│   │       └── maintenance_screen.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── case_provider.dart
│   │   ├── model_provider.dart
│   │   ├── research_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── widgets/
│   │   ├── custom_app_bar.dart
│   │   ├── neural_network_visualizer.dart
│   │   ├── heatmap_viewer.dart
│   │   ├── image_carousel.dart
│   │   └── ... (many specialized widgets)
│   │
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── supabase_service.dart
│   │   ├── api_service.dart
│   │   └── file_service.dart
│   │
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── case_model.dart
│   │   ├── model_performance_model.dart
│   │   └── experimental_result_model.dart
│   │
│   └── utils/
│       ├── validators.dart
│       ├── formatters.dart
│       ├── image_utils.dart
│       └── datetime_utils.dart
│
├── assets/
│   └── ai/
│       └── models/
│           ├── brain/
│           ├── spine/
│           └── chest/
│
├── test/
│   ├── unit_test/
│   └── widget_test/
│
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.x or higher
- Firebase CLI
- Supabase CLI (optional)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd NeuroVision-AI

# Install dependencies
flutter pub get
```

### Configuration

1. **Firebase Setup**
   - Follow the official Firebase documentation to add your Flutter app to a Firebase project
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`

2. **Environment Variables**
   - Create a `.env` file in the root directory:
     ```bash
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```

### Running the App

```bash
# Run on a simulator or device
flutter run

# Build for Android
flutter build apk --debug

# Build for iOS
flutter build ios
```
