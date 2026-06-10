# server/app/ml/brain/attention_unet.py
"""
Attention U-Net — EXACT architecture from training code.

From attention-u-net.ipynb (ISLES-2022 stroke lesion segmentation):
    AttentionUnet(
        spatial_dims=3,
        in_channels=3,       # DWI + ADC + FLAIR channels
        out_channels=1,      # Binary lesion mask
        channels=(16, 32, 64, 128, 256),
        strides=(2, 2, 2, 2)
    )

Input:  (B, 3, D, H, W) — 3D volumetric (DWI, ADC, FLAIR)
Output: (B, 1, D, H, W) — binary lesion segmentation mask
Best val Dice: 0.7789 | Test Dice: 0.7274

Inference note:
  For 2D image inputs from the Flutter app, we slice and run
  sliding_window_inference over pseudo-3D volumes (Z=1 slice).
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np

from monai.networks.nets import AttentionUnet
from monai.inferers import sliding_window_inference

ROI_SIZE = (64, 64, 64)


class AttentionUNetModel(nn.Module):
    """
    Wrapper around MONAI AttentionUnet matching the exact trained checkpoint.

    Exact config from training notebook:
        AttentionUnet(spatial_dims=3, in_channels=3, out_channels=1,
                      channels=(16, 32, 64, 128, 256), strides=(2, 2, 2, 2))
    """

    TASK = "Stroke Lesion Segmentation (ISLES-2022)"
    MODALITIES = ["DWI", "ADC", "FLAIR"]

    def __init__(self):
        super().__init__()
        self.model = AttentionUnet(
            spatial_dims=3,
            in_channels=3,       # DWI + ADC + FLAIR
            out_channels=1,      # Binary lesion mask
            channels=(16, 32, 64, 128, 256),
            strides=(2, 2, 2, 2),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, D, H, W) — 3-channel volumetric input
        Returns:
            (B, 1, D, H, W) — raw logits (apply sigmoid for probabilities)
        """
        return self.model(x)

    def segment_3d(self, volume: torch.Tensor) -> torch.Tensor:
        """
        Run sliding window inference on a full 3D volume.
        Args:
            volume: (1, 3, D, H, W) — single 3D subject
        Returns:
            (1, 1, D, H, W) — probability map [0, 1]
        """
        self.eval()
        with torch.no_grad():
            logits = sliding_window_inference(
                volume, ROI_SIZE, sw_batch_size=4,
                predictor=self.model, overlap=0.6
            )
            return torch.sigmoid(logits)

    def segment_2d_slice(self, image_tensor: torch.Tensor) -> torch.Tensor:
        """
        Segment a 2D slice by treating it as a single-slice 3D volume.
        Args:
            image_tensor: (1, 3, H, W) — 2D image with 3 channels
        Returns:
            (H, W) numpy array — binary lesion mask
        """
        # Unsqueeze depth dim: (1, 3, 1, H, W)
        vol = image_tensor.unsqueeze(2)
        # Pad depth to minimum roi_size[0]
        d_needed = ROI_SIZE[0]
        vol = vol.repeat(1, 1, d_needed, 1, 1)
        probs = self.segment_3d(vol)
        # Take center slice and threshold
        mid = d_needed // 2
        mask = (probs[0, 0, mid] > 0.5).cpu().numpy().astype(np.uint8)
        return mask

    def classify_from_mask(self, mask: np.ndarray) -> dict:
        """
        Derive a classification result from the segmentation mask.
        Returns lesion presence + estimated coverage percentage.
        """
        lesion_pixels = int(mask.sum())
        total_pixels = int(mask.size)
        coverage = round(lesion_pixels / total_pixels * 100, 2) if total_pixels > 0 else 0.0
        has_lesion = lesion_pixels > 0

        return {
            "prediction": "Stroke Lesion Detected" if has_lesion else "No Lesion",
            "lesion_coverage_pct": coverage,
            "lesion_voxels": lesion_pixels,
        }
