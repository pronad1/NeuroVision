# server/app/api/routes/brain.py
"""
Brain MRI inference API endpoints.

All three brain models are 3D segmentation networks trained on ISLES-2022:
  - DERNet:        LSCBlock + BiMambaSim + BAGF, f=(32,64,128)
  - SegResNet:     MONAI SegResNet init_filters=32, blocks_down=[1,2,2,4]
  - AttentionUNet: MONAI AttentionUnet channels=(16,32,64,128,256)

Input: single 2D brain MRI image (PNG/JPEG)
Processing: promote to pseudo-3D → sliding window inference → lesion mask
Output: lesion presence, coverage %, segmentation mask overlay
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from app.ml.inference import classify_brain

router = APIRouter()


class BrainResult(BaseModel):
    prediction: str
    confidence: float
    modality: str
    model_used: str
    all_probabilities: dict
    heatmap_base64: Optional[str] = None
    segmentation_mask_base64: Optional[str] = None
    lesion_coverage_pct: float = 0.0
    lesion_voxels: int = 0
    severity: str
    message: str


def _severity(prediction: str, coverage: float) -> str:
    if "No Lesion" in prediction or "No lesion" in prediction:
        return "None"
    if coverage > 10:
        return "High"
    if coverage > 2:
        return "Medium"
    return "Low"


@router.post("/analyze", response_model=BrainResult)
async def analyze_brain_mri(
    file: UploadFile = File(..., description="Brain MRI image (PNG or JPEG). Single 2D slice."),
    model: Optional[str] = Query(
        default=None,
        description="Brain segmentation model to use (ignored, ensemble is always used)"
    ),
):
    """
    Analyze a brain MRI image for stroke lesion segmentation.

    **Models:**
    - **Ensemble** — Integrates DERNet, SegResNet, and AttentionUNet via majority voting.

    **Dataset:** ISLES-2022 (Ischemic Stroke Lesion Segmentation)

    Returns segmentation mask, lesion coverage, and binary prediction.
    """
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    try:
        result = classify_brain(image_bytes, model_name=model)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")

    coverage = result.get("lesion_coverage_pct", 0.0)
    sev = _severity(result["prediction"], coverage)
    result["severity"] = sev
    result["message"] = (
        f"Brain MRI analysis complete. "
        f"{result['prediction']} — lesion coverage: {coverage:.2f}%. "
        "Clinical validation required before any diagnostic use."
    )
    return result


@router.get("/models")
async def list_brain_models():
    """List available brain MRI models with architecture details."""
    return {
        "dataset": "ISLES-2022 (Ischemic Stroke Lesion Segmentation)",
        "task": "3D Binary Segmentation → Normal / Stroke Lesion",
        "input": "Single 2D brain MRI slice (promoted to pseudo-3D internally)",
        "models": [
            {
                "name": "DERNet",
                "architecture": "3D U-Net with LSCBlock (multi-scale conv) + BiMambaSim (BiGRU bottleneck) + BAGF (gated fusion)",
                "params": "in_c=3, out_c=1, f=(32, 64, 128)",
                "best_val_dice": 0.8171,
            },
            {
                "name": "SegResNet",
                "architecture": "MONAI SegResNet with gradient accumulation (x4) + 3-flip TTA",
                "params": "init_filters=32, blocks_down=[1,2,2,4], blocks_up=[1,1,1], dropout=0.2",
                "test_dice_tta": 0.7819,
            },
            {
                "name": "AttentionUNet",
                "architecture": "MONAI AttentionUnet with attention gates",
                "params": "channels=(16,32,64,128,256), strides=(2,2,2,2)",
                "best_val_dice": 0.7789,
            },
        ],
    }
