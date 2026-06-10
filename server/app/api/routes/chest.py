# server/app/api/routes/chest.py
"""
Chest X-Ray inference API endpoints.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from app.ml.inference import classify_chest

router = APIRouter()


@router.post("/analyze")
async def analyze_chest_xray(
    file: UploadFile = File(..., description="Chest X-ray image (PNG or JPG)"),
):
    """
    Analyze a chest X-ray scan.
    Currently uses ResNet50 as a placeholder.
    Dedicated chest model (CheXNet / DenseNet-121) coming soon.
    """
    image_bytes = await file.read()
    try:
        result = classify_chest(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    prediction = result.get("prediction", "Unknown")
    result["severity"] = "None" if prediction == "Normal" else "Medium"
    result["message"] = (
        f"Chest X-ray analysis: {prediction} ({result.get('confidence', 0):.1f}%). "
        "Note: Dedicated chest model integration in progress."
    )
    return result
