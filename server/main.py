# server/main.py
"""
NeuroVision AI — FastAPI Inference Server
Serves predictions from trained PyTorch models for brain, spine, and chest imaging.
"""

import os
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from app.core.config import settings
from app.api.routes import brain, spine, chest, heart, health, report
from app.core.model_registry import ModelRegistry

app = FastAPI(
    title="NeuroVision AI Inference API",
    description="AI-powered medical image analysis for brain MRI, spine MRI, and chest X-ray",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — allow Flutter app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health.router, prefix="/api/v1", tags=["Health"])
app.include_router(brain.router, prefix="/api/v1/brain", tags=["Brain MRI"])
app.include_router(spine.router, prefix="/api/v1/spine", tags=["Spine MRI"])
app.include_router(chest.router, prefix="/api/v1/chest", tags=["Chest X-Ray"])
app.include_router(heart.router, prefix="/api/v1/heart", tags=["Heart (Echo)"])
app.include_router(report.router, prefix="/api/v1/report", tags=["AI Report Generation"])

@app.on_event("startup")
async def startup_event():
    """Pre-load all models on server startup for fast inference."""
    import torch
    # Limit CPU threads to prevent thread contention and high CPU load
    torch.set_num_threads(2)
    print("NeuroVision AI - Loading models...")
    ModelRegistry.load_all()
    print("All models loaded and ready.")

    # Pre-warm the YOLO spine model so the first user request is fast
    from app.ml.inference import _get_yolo_model
    print("[INFO] Pre-warming YOLO11 spine model...")
    _get_yolo_model()
    print("[INFO] YOLO11 warm-up complete.")

@app.get("/")
async def root():
    return {
        "service": "NeuroVision AI Inference API",
        "version": "1.0.0",
        "status": "running",
        "models": ModelRegistry.list_loaded(),
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
