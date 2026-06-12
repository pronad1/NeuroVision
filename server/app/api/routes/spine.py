# server/app/api/routes/spine.py
"""
Spine X-ray inference API endpoints.

All three spine models are binary classifiers trained on VinDr-SpineXR:
  - DenseNet: timm densenet121, 384×384, BCEWithLogitsLoss(pos_weight=1.3)
  - EfficientNet: timm tf_efficientnetv2_s, 384×384, MixUp + RandomErasing
  - ResNet50: torchvision resnet50, fc=Linear(2048,1), 224×224

Output: Normal / Abnormal with AUROC-validated confidence.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from app.ml.inference import classify_spine

router = APIRouter()


class SpineResult(BaseModel):
    prediction: str
    confidence: float
    modality: str
    model_used: str
    all_probabilities: dict
    heatmap_base64: Optional[str] = None
    severity: str
    message: str


@router.post("/analyze", response_model=SpineResult)
async def analyze_spine_xray(
    file: UploadFile = File(..., description="Spine X-ray image (PNG or JPEG)"),
    model: Optional[str] = Query(
        default=None,
        description="Spine classification model (ignored, ensemble is always used)"
    ),
):
    """
    Classify a spine X-ray as Normal or Abnormal.

    **Models (VinDr-SpineXR, MICCAI 2026):**
    - **Ensemble** — Averages predictions from EfficientNet, DenseNet, and ResNet50.
    """
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        result = classify_spine(image_bytes)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")

    prediction = result["prediction"]
    result["severity"] = "None" if prediction == "Normal" else "Medium"
    result["message"] = (
        f"Spine X-ray classified as {prediction} "
        f"({result['confidence']:.1f}% confidence). "
        "Radiologist review recommended for clinical decisions."
    )
    return result


@router.get("/models")
async def list_spine_models():
    """List available spine models with training metrics."""
    return {
        "dataset": "VinDr-SpineXR (MICCAI 2026 Paper)",
        "task": "Binary Classification — Normal / Abnormal",
        "models": [
            {
                "name": "EfficientNet",
                "architecture": "timm tf_efficientnetv2_s (num_classes=1)",
                "image_size": 384,
                "auroc": "89.44%",
                "sensitivity": "70.80%",
                "specificity": "91.12%",
                "f1": "79.34%",
            },
            {
                "name": "DenseNet",
                "architecture": "timm densenet121 (num_classes=1)",
                "image_size": 384,
                "auroc": "86.93%",
                "sensitivity": "80.39%",
                "specificity": "79.32%",
                "f1": "79.55%",
            },
            {
                "name": "ResNet50",
                "architecture": "torchvision resnet50, fc=Linear(2048,1)",
                "image_size": 224,
                "auroc": "88.88%",
                "sensitivity": "82.72%",
                "specificity": "78.13%",
                "f1": "80.15%",
            },
        ],
    }
