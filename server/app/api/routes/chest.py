# server/app/api/routes/chest.py
"""
Chest X-Ray inference API endpoints.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.ml.inference import classify_chest

router = APIRouter()


class ChestResult(BaseModel):
    prediction: str
    confidence: float
    modality: str
    model_used: str
    all_probabilities: dict
    heatmap_base64: Optional[str] = None
    segmentation_mask_base64: Optional[str] = None
    severity: str
    message: str


@router.post("/analyze", response_model=ChestResult)
async def analyze_chest_xray(
    file: UploadFile = File(..., description="Chest X-ray image (PNG or JPG)"),
):
    """
    Analyze a chest X-ray scan for Pneumonia/Abnormality.
    """
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        result = classify_chest(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    prediction = result.get("prediction", "Unknown")
    result["severity"] = "None" if "Normal" in prediction else "Medium"
    result["message"] = (
        f"Chest X-ray analysis: {prediction} ({result.get('confidence', 0):.1f}%). "
        "Clinical validation required before any diagnostic use."
    )
    return result


@router.get("/models")
async def list_chest_models():
    """List available chest models."""
    return {
        "dataset": "ChestX-ray14",
        "task": "Binary Classification — Normal / Pneumonia",
        "models": [
            {
                "name": "CheXNet",
                "architecture": "DenseNet-121 fine-tuned on ChestX-ray14",
                "auroc": "84.22%",
            },
            {
                "name": "ResNet50",
                "architecture": "ResNet-50 baseline",
                "auroc": "80.11%",
            },
            {
                "name": "CNN-Classifier",
                "architecture": "Custom CNN",
                "auroc": "78.44%",
            },
        ],
    }

