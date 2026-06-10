# server/app/ml/preprocessing.py
"""
Image preprocessing — matches exact training transforms for each model.

Brain (DERNet / SegResNet / AttentionUNet):
  - Training used MONAI NormalizeIntensityd (nonzero=True, channel_wise=True)
  - Input: DWI + ADC + FLAIR stacked as 3 channels
  - For single 2D image: duplicate across 3 channels + normalize per-channel
  - Resize to 224×224 for inference

Spine (DenseNet / EfficientNet):
  - Training: Resize(384, 384) + Normalize([0.485,0.456,0.406], [0.229,0.224,0.225])

Spine (ResNet50):
  - Training: Resize(224, 224) + same ImageNet normalization
"""

import io
import numpy as np
import torch
from PIL import Image
from torchvision import transforms


# ── Shared ImageNet normalization ─────────────────────────────────────────────
_IMAGENET_MEAN = [0.485, 0.456, 0.406]
_IMAGENET_STD  = [0.229, 0.224, 0.225]


def _make_spine_transform(img_size: int) -> transforms.Compose:
    """Matches val_transform from all three spine training scripts."""
    return transforms.Compose([
        transforms.Resize((img_size, img_size)),
        transforms.ToTensor(),
        transforms.Normalize(_IMAGENET_MEAN, _IMAGENET_STD),
    ])


# ── Loaders ───────────────────────────────────────────────────────────────────

def load_image(image_bytes: bytes) -> Image.Image:
    """Load raw bytes → PIL Image (RGB)."""
    img = Image.open(io.BytesIO(image_bytes))
    if img.mode != "RGB":
        img = img.convert("RGB")
    return img


# ── Brain preprocessing ───────────────────────────────────────────────────────

def preprocess_brain_3d(image_bytes: bytes, img_size: int = 224) -> torch.Tensor:
    """
    Preprocess a single 2D brain MRI image for 3D model inference.

    Because the 3D models expect (B, 3, D, H, W) with DWI+ADC+FLAIR channels,
    and we only have one 2D image from the app, we:
      1. Resize to img_size × img_size
      2. Convert to grayscale (intensity only)
      3. Repeat the channel 3 times (simulating DWI=ADC=FLAIR=same intensity)
      4. Normalize each channel by its own mean/std (nonzero voxels only),
         matching MONAI NormalizeIntensityd(nonzero=True, channel_wise=True)

    Returns:
        (1, 3, img_size, img_size) float32 tensor
    """
    img = load_image(image_bytes).resize((img_size, img_size))
    # Grayscale
    gray = np.array(img.convert("L"), dtype=np.float32) / 255.0  # (H, W)

    # Stack 3 identical channels (DWI, ADC, FLAIR approximation)
    volume = np.stack([gray, gray, gray], axis=0)  # (3, H, W)

    # Per-channel nonzero normalization (matches MONAI NormalizeIntensityd)
    for c in range(3):
        nonzero = volume[c][volume[c] > 0]
        if len(nonzero) > 0:
            mean_val = nonzero.mean()
            std_val  = nonzero.std()
            if std_val > 1e-6:
                volume[c] = (volume[c] - mean_val) / std_val

    tensor = torch.from_numpy(volume).float().unsqueeze(0)  # (1, 3, H, W)
    return tensor


# ── Spine preprocessing ───────────────────────────────────────────────────────

def preprocess_spine(image_bytes: bytes, img_size: int = 384) -> torch.Tensor:
    """
    Matches val_transform from all three spine training scripts.
    Resize → ToTensor → ImageNet normalize.

    Args:
        img_size: 384 for DenseNet/EfficientNet, 224 for ResNet50
    Returns:
        (1, 3, img_size, img_size)
    """
    img = load_image(image_bytes)
    t = _make_spine_transform(img_size)(img)
    return t.unsqueeze(0)


# ── Chest preprocessing ───────────────────────────────────────────────────────

def preprocess_chest(image_bytes: bytes, img_size: int = 224) -> torch.Tensor:
    """Standard chest X-ray preprocessing."""
    img = load_image(image_bytes)
    t = _make_spine_transform(img_size)(img)
    return t.unsqueeze(0)
