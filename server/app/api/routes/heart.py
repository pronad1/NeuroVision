# server/app/api/routes/heart.py
"""
Heart Echo inference API endpoints.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.ml.inference import classify_heart

router = APIRouter()


class HeartResult(BaseModel):
    prediction: str
    confidence: float
    modality: str
    model_used: str
    all_probabilities: dict
    heatmap_base64: Optional[str] = None
    segmentation_mask_base64: Optional[str] = None
    severity: str
    message: str


@router.post("/analyze", response_model=HeartResult)
async def analyze_heart_echo(
    file: UploadFile = File(..., description="Heart Echo image (PNG or JPG)"),
):
    """
    Analyze a Heart Echo scan for Cardiomegaly.
    """
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        result = classify_heart(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    prediction = result.get("prediction", "Unknown")
    result["severity"] = "None" if "Normal" in prediction else "Medium"
    result["message"] = (
        f"Heart Echo analysis: {prediction} ({result.get('confidence', 0):.1f}%). "
        "Clinical validation required before any diagnostic use."
    )
    return result


@router.get("/models")
async def list_heart_models():
    """List available heart models."""
    return {
        "dataset": "EchoNet-Dynamic",
        "task": "Binary Classification — Normal / Cardiomegaly",
        "models": [
            {
                "name": "CatBoost-Echo",
                "architecture": "CatBoost Classifier on echocardiogram tabular metrics",
                "accuracy": "92.4%",
            },
            {
                "name": "ResNet50-Echo",
                "architecture": "ResNet-50 Echo image classifier",
                "accuracy": "88.7%",
            },
        ],
    }
