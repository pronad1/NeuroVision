# NeuroVision AI

An Enterprise Multimodal Explainable Medical Diagnosis and Lesion Localization Ecosystem Using Deep Learning

## 🚀 Project Overview

**NeuroVision AI** is a cutting-edge medical imaging platform designed to assist doctors, radiologists, and researchers in diagnosing neurological and cardiovascular conditions through advanced deep learning models. The platform integrates multiple AI pipelines for brain, spine, heart, and chest imaging, providing lesion detection, segmentation, explainable AI (Grad-CAM), and research monitoring in a secure, enterprise-grade environment.

## ✨ Key Features

### Multimodal Imaging Analysis
- 🧠 **Brain Intelligence**: Ischemic stroke analysis, lesion segmentation (DERNet, SegResNet)
- 🦴 **Spine Intelligence**: Vertebral lesion detection and classification (DenseNet, EfficientNetV2)
- ❤️ **Heart Intelligence**: Cardiovascular abnormality detection and cardiac imaging analysis
- 🫁 **Chest X-Ray**: Pneumonia and tuberculosis screening (future module)

### Explainable AI Engine
- Visualizes AI reasoning through Grad-CAM heatmaps and activation maps
- Builds trust by showing *why* the AI made a prediction
- Enhances clinical validation and understanding

### Research & Monitoring
- Tracks model performance and experiment metrics
- Compares deep learning architectures (ResNet, DenseNet, etc.)
- Visualizes training curves, confusion matrices, and validation results

### Enterprise Clinical Workflow
- Secure, anonymized medical case management
- Role-based access control (Doctor, Radiologist, Researcher)
- Professional DICOM viewer and annotation tools
- Integrated reporting and diagnostic workflows

## 👥 User Roles

1. **Doctor**: Reviews AI diagnosis, monitors case progression, compares scans, and approves final reports.
2. **Radiologist**: Handles professional medical image interpretation, lesion annotation, segmentation validation, and AI localization comparison.
3. **Researcher**: Monitors AI models, tracks experiments, analyzes dataset metrics, compares architectures, and reviews training curves.

## 🔒 Security & Privacy Model

The system follows an **internal anonymized medical architecture**:
- ✅ No public patient access
- ✅ No direct patient accounts
- ✅ Internal institutional usage only
- ✅ Anonymized medical cases using unique IDs (e.g., `CASE-2026-001`)
- ✅ Role-based access control and restricted dataset visibility

## 🔧 Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend Framework** | Flutter 3.x |
| **State Management** | Provider |
| **Authentication & DB**| Firebase (Auth, Firestore, Storage) |
| **Medical Imaging DB** | Supabase |
| **Backend API** | FastAPI (upcoming) |
| **AI Models Engine** | PyTorch, MONAI |
| **Computer Vision** | OpenCV |

## 🏗️ Current Project Status

The following milestones have already been achieved in the repository:
1. **Flutter Frontend Scaffolded**: The core application (`software/`) is initialized using Flutter.
2. **Architectural Layout**: A robust `lib/src` directory structure has been created to support large-scale enterprise development.
3. **Role & Module Routing**: All UI screens and dashboard placeholders for Doctors, Radiologists, and Researchers have been mapped out.
4. **AI Pipelines Configured**: 
   - Dedicated analysis hubs for **Brain**, **Spine**, **Heart**, and **Chest** have been set up in the UI routing.
   - Core directories for AI model assets (`assets/ai/models/`) are established for each modality.
5. **Service Layer Setup**: Placeholder service integrations for Firebase, Supabase, and custom APIs have been generated.
6. **State & Data Foundation**: Providers and data models mapping the clinical workflows are structured and ready for logic implementation.

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Firebase CLI
- Supabase CLI (optional)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd NeuroVision-AI/software

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

### Deploy to Firebase Hosting
```bash
# Ensure Node and npm are installed
node -v
npm -v

# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Navigate to the Flutter project directory
cd software

# Initialize Firebase Hosting
firebase init hosting

# Build the web app
flutter build web

# Deploy to Firebase Hosting
firebase deploy
```