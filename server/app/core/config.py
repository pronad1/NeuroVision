# server/app/core/config.py
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent  # project root /server

class Settings:
    # Server
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", 8000))
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"

    # Model paths
    BRAIN_MODEL_DIR: Path = BASE_DIR / "ml" / "brain"
    SPINE_MODEL_DIR: Path = BASE_DIR / "ml" / "spine"
    CHEST_MODEL_DIR: Path = BASE_DIR / "ml" / "chest"

    # Brain model files
    DERNET_PATH: str = str(BRAIN_MODEL_DIR / "DERNet_best_val.pth")
    SEGRESNET_PATH: str = str(BRAIN_MODEL_DIR / "SegResNet_best_val.pth")
    ATTENTION_UNET_PATH: str = str(BRAIN_MODEL_DIR / "AttentionUnet_best_val.pth")

    # Spine model files
    DENSENET_PATH: str = str(SPINE_MODEL_DIR / "densenet.pth")
    EFFICIENTNET_PATH: str = str(SPINE_MODEL_DIR / "efficientnet.pth")
    RESNET50_PATH: str = str(SPINE_MODEL_DIR / "resnet50.pth")

    # Image settings
    BRAIN_IMAGE_SIZE: int = 224
    SPINE_IMAGE_SIZE: int = 224
    CHEST_IMAGE_SIZE: int = 224

    # Device (auto-detect GPU)
    DEVICE: str = "cuda" if __import__("torch").cuda.is_available() else "cpu"

    # Firebase (for auth verification)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "")

settings = Settings()
