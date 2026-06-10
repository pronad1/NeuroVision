# NeuroVision AI — Inference Server

FastAPI-based AI inference server that serves predictions from trained PyTorch models.

## Models Included

| Model | File | Modality | Classes |
|-------|------|----------|---------|
| DERNet | `ml/brain/DERNet_best_val.pth` | Brain MRI | Normal, Ischemic Stroke, Hemorrhage, Tumor |
| SegResNet | `ml/brain/SegResNet_best_val.pth` | Brain MRI | Segmentation + Classification |
| Attention U-Net | `ml/brain/AttentionUnet_best_val.pth` | Brain MRI | Segmentation + Classification |
| DenseNet-201 | `ml/spine/densenet.pth` | Spine MRI | Normal, Disc Herniation, Stenosis, Fracture, Spondylolisthesis |
| EfficientNetV2 | `ml/spine/efficientnet.pth` | Spine MRI | Same 5 classes |
| ResNet-50 | `ml/spine/resnet50.pth` | Spine MRI | Same 5 classes |

## Setup

```bash
# 1. Create a virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Linux/Mac

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run the server
cd server
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Server health + loaded models |
| POST | `/api/v1/brain/analyze?model=DERNet` | Brain MRI classification + Grad-CAM |
| POST | `/api/v1/brain/segment?model=AttentionUNet` | Brain lesion segmentation |
| POST | `/api/v1/spine/analyze?model=EfficientNet` | Spine MRI classification |
| POST | `/api/v1/chest/analyze` | Chest X-ray analysis |

Interactive API docs: `http://localhost:8000/docs`

## Flutter Integration

The Flutter app connects to this server via `lib/src/services/ai_service.dart`.

For **Android emulator** change `_baseUrl` to:
```dart
static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
```

For **real device** on same WiFi:
```dart
static const String _baseUrl = 'http://192.168.x.x:8000/api/v1';
```

## Adding Chest X-Ray Model

Place your chest model at `ml/chest/` and register it in:
- `app/core/model_registry.py`
- `app/api/routes/chest.py`
