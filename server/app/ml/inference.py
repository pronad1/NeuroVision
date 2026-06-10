# server/app/ml/inference.py
"""
Core inference engine.

Brain models (DERNet, SegResNet, AttentionUNet):
  - 3D volumetric segmentation on (DWI+ADC+FLAIR)
  - For single 2D image input: promoted to pseudo-3D via depth repetition
  - Returns: lesion mask + coverage + Grad-CAM-style heatmap overlay

Spine models (DenseNet, EfficientNet, ResNet50):
  - 2D binary classification (Normal / Abnormal)
  - VinDr-SpineXR dataset (384×384 or 224×224)
  - Returns: prediction + confidence
"""

import io
import base64
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
import cv2
from typing import Optional

from app.core.model_registry import ModelRegistry
from app.ml.preprocessing import (
    preprocess_brain_3d, preprocess_spine, preprocess_chest, load_image
)


# ── Grad-CAM ─────────────────────────────────────────────────────────────────

class GradCAM:
    """Generic Grad-CAM for 2D or 3D conv layers."""

    def __init__(self, model: torch.nn.Module, target_layer):
        self.model = model
        self.gradients: Optional[torch.Tensor] = None
        self.activations: Optional[torch.Tensor] = None

        target_layer.register_forward_hook(self._save_activation)
        target_layer.register_full_backward_hook(self._save_gradient)

    def _save_activation(self, module, input, output):
        self.activations = output.detach()

    def _save_gradient(self, module, grad_input, grad_output):
        self.gradients = grad_output[0].detach()

    def generate(self, input_tensor: torch.Tensor, class_idx: int) -> np.ndarray:
        self.model.zero_grad()
        output = self.model(input_tensor)
        if output.dim() > 2:
            # Segmentation output — pool to scalar for backward
            score = output[:, class_idx].mean()
        else:
            score = output[0, class_idx]
        score.backward()

        # Average gradients over spatial dims
        weights = self.gradients.mean(dim=list(range(2, self.gradients.dim())), keepdim=True)
        cam = (weights * self.activations).sum(dim=1, keepdim=True)
        cam = F.relu(cam)

        # Collapse 3D to 2D if needed
        if cam.dim() == 5:
            cam = cam[:, :, cam.shape[2] // 2]  # take center slice

        cam = F.interpolate(cam, size=(224, 224), mode="bilinear", align_corners=False)
        cam = cam.squeeze().cpu().numpy()
        cam -= cam.min()
        if cam.max() > 0:
            cam /= cam.max()
        return cam


def heatmap_to_base64(cam: np.ndarray, original_image_bytes: bytes) -> str:
    heatmap = cv2.applyColorMap(np.uint8(255 * cam), cv2.COLORMAP_JET)
    heatmap = cv2.cvtColor(heatmap, cv2.COLOR_BGR2RGB)
    orig = np.array(load_image(original_image_bytes).resize((224, 224)))
    overlay = cv2.addWeighted(orig, 0.6, heatmap, 0.4, 0)
    pil_out = Image.fromarray(overlay)
    buf = io.BytesIO()
    pil_out.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def mask_to_base64(mask: np.ndarray) -> str:
    """Encode a binary mask as a base64 PNG with color overlay."""
    colored = np.zeros((*mask.shape, 3), dtype=np.uint8)
    colored[mask > 0] = [255, 80, 80]  # red lesion
    pil = Image.fromarray(colored)
    buf = io.BytesIO()
    pil.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


# ── Brain Inference ───────────────────────────────────────────────────────────

def classify_brain(image_bytes: bytes, model_name: str = "DERNet") -> dict:
    """
    Run brain MRI segmentation on a 2D image slice.
    Internally promotes to pseudo-3D, runs sliding-window inference,
    returns mask + coverage + heatmap.

    Args:
        image_bytes: raw PNG/JPEG bytes
        model_name: "DERNet" | "SegResNet" | "AttentionUNet"
    """
    model = ModelRegistry.get(model_name)
    if model is None:
        raise ValueError(f"Model '{model_name}' not loaded. Available: {ModelRegistry.list_loaded()}")

    device = ModelRegistry.device

    # Preprocess: (1, 3, H, W) → promote to (1, 3, 64, H_r, W_r)
    tensor_2d = preprocess_brain_3d(image_bytes)  # (1, 3, 224, 224)
    tensor_2d = tensor_2d.to(device)

    # Run 2D-slice segmentation
    mask = model.segment_2d_slice(tensor_2d)   # (H, W) binary np array
    cls_result = model.classify_from_mask(mask)

    # Build heatmap from mask
    mask_b64 = mask_to_base64(mask)

    # Confidence proxy: coverage percentage normalised
    coverage = cls_result["lesion_coverage_pct"]
    confidence = min(round(coverage * 5, 1), 99.9) if coverage > 0 else round(
        (1 - coverage / 100) * 95, 1
    )

    return {
        "prediction": cls_result["prediction"],
        "confidence": confidence,
        "modality": "Brain MRI",
        "model_used": model_name,
        "all_probabilities": {
            "No Lesion": round(100 - confidence, 1),
            "Stroke Lesion": round(confidence, 1),
        },
        "heatmap_base64": mask_b64,           # lesion mask overlay
        "segmentation_mask_base64": mask_b64,
        "lesion_coverage_pct": coverage,
        "lesion_voxels": cls_result["lesion_voxels"],
    }


# ── Spine Inference ───────────────────────────────────────────────────────────

def classify_spine(image_bytes: bytes, model_name: str = "EfficientNet") -> dict:
    """
    Run spine X-ray binary classification.
    Returns Normal / Abnormal with confidence.
    """
    model = ModelRegistry.get(model_name)
    if model is None:
        raise ValueError(f"Model '{model_name}' not loaded.")

    device = ModelRegistry.device

    # Use model-specific image size
    img_size = getattr(model, "IMAGE_SIZE", 384)
    tensor = preprocess_spine(image_bytes, img_size=img_size).to(device)

    with torch.no_grad():
        prob_abnormal = float(model.predict_proba(tensor).cpu().item())

    prob_normal = round((1 - prob_abnormal) * 100, 2)
    prob_abnormal_pct = round(prob_abnormal * 100, 2)

    prediction = "Abnormal" if prob_abnormal > 0.5 else "Normal"
    confidence = prob_abnormal_pct if prediction == "Abnormal" else prob_normal

    return {
        "prediction": prediction,
        "confidence": round(confidence, 2),
        "modality": "Spine MRI",
        "model_used": model_name,
        "all_probabilities": {
            "Normal": prob_normal,
            "Abnormal": prob_abnormal_pct,
        },
        "heatmap_base64": None,
    }


# ── Chest Inference ───────────────────────────────────────────────────────────

def classify_chest(image_bytes: bytes) -> dict:
    """Placeholder — dedicated chest model coming soon."""
    return {
        "prediction": "Pending",
        "confidence": 0.0,
        "modality": "Chest X-Ray",
        "model_used": "No chest model loaded",
        "all_probabilities": {},
        "heatmap_base64": None,
        "message": "Dedicated chest model integration in progress.",
    }
