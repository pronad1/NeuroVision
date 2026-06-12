# server/app/core/model_registry.py
"""
Central model registry — loads all trained .pth checkpoints.

Checkpoint formats handled:
  Brain (DERNet / AttentionUNet / SegResNet):  raw state_dict
  Spine (DenseNet / EfficientNet / ResNet50):  {'model_state_dict': ...}
"""

import torch
import torch.nn as nn
from pathlib import Path
from typing import Optional
import traceback

from app.core.config import settings
from app.ml.brain.dernet import DERNet
from app.ml.brain.segresnet import SegResNetModel
from app.ml.brain.attention_unet import AttentionUNetModel
from app.ml.spine.densenet_model import DenseNetSpine
from app.ml.spine.efficientnet_model import EfficientNetSpine
from app.ml.spine.resnet_model import ResNetSpine


class _Registry:
    def __init__(self):
        self._models: dict = {}
        self._device = torch.device(settings.DEVICE)

    def _load(self, name: str, model: nn.Module, path: str) -> bool:
        """Load a checkpoint onto the device. Handles both raw and wrapped formats."""
        try:
            if not Path(path).exists():
                print(f"  [WARN] Model file not found: {path}")
                return False

            ckpt = torch.load(path, map_location=self._device, weights_only=False)

            # Unwrap checkpoint formats
            if isinstance(ckpt, dict):
                if "model_state_dict" in ckpt:
                    # Spine models: {'epoch', 'model_state_dict', ...}
                    state_dict = ckpt["model_state_dict"]
                elif "model" in ckpt:
                    state_dict = ckpt["model"]
                elif "state_dict" in ckpt:
                    state_dict = ckpt["state_dict"]
                else:
                    # Brain models: raw state_dict saved via torch.save(m.state_dict(), path)
                    state_dict = ckpt
            else:
                state_dict = ckpt

            # Strip 'module.' prefix ONLY if it starts with 'module.'
            cleaned = {}
            for k, v in state_dict.items():
                k_clean = k[7:] if k.startswith("module.") else k
                cleaned[k_clean] = v

            # Load into model.model if this is a wrapper
            target = model.model if hasattr(model, "model") else model

            target.load_state_dict(cleaned, strict=True)
            model.to(self._device)
            model.eval()
            self._models[name] = model
            print(f"  [OK] {name} loaded ({self._device})")
            return True

        except Exception as e:
            print(f"  [ERROR] Failed to load {name}: {e}")
            traceback.print_exc()
            return False

    def load_all(self):
        print(f"\n  Device: {self._device}")
        print("\n  -- Brain Models --------------------------------------")
        # Brain: 3D segmentation — raw state_dict
        self._load("DERNet",        DERNet(),           settings.DERNET_PATH)
        self._load("SegResNet",     SegResNetModel(),   settings.SEGRESNET_PATH)
        self._load("AttentionUNet", AttentionUNetModel(), settings.ATTENTION_UNET_PATH)

        print("\n  -- Spine Models --------------------------------------")
        # Spine: binary classification — wrapped {'model_state_dict': ...}
        self._load("DenseNet",      DenseNetSpine(),    settings.DENSENET_PATH)
        self._load("EfficientNet",  EfficientNetSpine(), settings.EFFICIENTNET_PATH)
        self._load("ResNet50",      ResNetSpine(),      settings.RESNET50_PATH)

    def get(self, name: str) -> Optional[nn.Module]:
        return self._models.get(name)

    def list_loaded(self) -> list[str]:
        return list(self._models.keys())

    @property
    def device(self) -> torch.device:
        return self._device


ModelRegistry = _Registry()
