# server/app/api/routes/health.py
from fastapi import APIRouter
from app.core.model_registry import ModelRegistry
from app.core.config import settings

router = APIRouter()

@router.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "device": str(ModelRegistry.device),
        "models_loaded": ModelRegistry.list_loaded(),
        "models_count": len(ModelRegistry.list_loaded()),
    }

@router.get("/version")
async def version():
    return {"version": "1.0.0", "name": "NeuroVision AI Inference API"}
