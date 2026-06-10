# server/app/ml/brain/segresnet.py
"""
SegResNet — EXACT architecture from training code ("God-Mode" engine).

From segresnet-modified.ipynb (ISLES-2022):
    SegResNet(
        spatial_dims=3,
        in_channels=3,              # DWI + ADC + FLAIR
        out_channels=1,             # Binary lesion mask
        init_filters=32,
        blocks_down=[1, 2, 2, 4],
        blocks_up=[1, 1, 1],
        dropout_prob=0.2
    )

Training extras: Gradient Accumulation (x4) + TTA (3-flip ensemble).
Best val Dice: 0.7801 | Test Dice WITH TTA: 0.7819
"""

import torch
import torch.nn as nn
import numpy as np

from monai.networks.nets import SegResNet
from monai.inferers import sliding_window_inference
from monai.data import decollate_batch

ROI_SIZE = (64, 64, 64)


class SegResNetModel(nn.Module):
    """
    Wrapper around MONAI SegResNet matching the exact trained checkpoint.

    Exact config from training notebook:
        SegResNet(spatial_dims=3, in_channels=3, out_channels=1,
                  init_filters=32, blocks_down=[1, 2, 2, 4],
                  blocks_up=[1, 1, 1], dropout_prob=0.2)
    """

    TASK = "Stroke Lesion Segmentation with TTA (ISLES-2022)"
    MODALITIES = ["DWI", "ADC", "FLAIR"]

    def __init__(self):
        super().__init__()
        self.model = SegResNet(
            spatial_dims=3,
            in_channels=3,
            out_channels=1,
            init_filters=32,
            blocks_down=[1, 2, 2, 4],
            blocks_up=[1, 1, 1],
            dropout_prob=0.2,
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, D, H, W)
        Returns:
            (B, 1, D, H, W) — raw logits
        """
        return self.model(x)

    def segment_3d(self, volume: torch.Tensor, use_tta: bool = True) -> torch.Tensor:
        """
        Run inference with optional Test-Time Augmentation (3-flip ensemble).
        Matches the exact TTA strategy used in training:
          - Prediction 1: original
          - Prediction 2: flip dim=2 (depth axis)
          - Prediction 3: flip dim=3 (height axis)
          → Average of 3 predictions

        Args:
            volume: (1, 3, D, H, W)
            use_tta: use 3-flip ensemble (default True)
        Returns:
            (1, 1, D, H, W) probability map [0, 1]
        """
        self.eval()
        with torch.no_grad():
            # Prediction 1: original
            p1 = torch.sigmoid(
                sliding_window_inference(volume, ROI_SIZE, 4, self.model, overlap=0.6)
            )
            if not use_tta:
                return p1

            # Prediction 2: flip depth axis
            v2 = torch.flip(volume, dims=[2])
            p2 = torch.flip(
                torch.sigmoid(sliding_window_inference(v2, ROI_SIZE, 4, self.model, overlap=0.6)),
                dims=[2],
            )

            # Prediction 3: flip height axis
            v3 = torch.flip(volume, dims=[3])
            p3 = torch.flip(
                torch.sigmoid(sliding_window_inference(v3, ROI_SIZE, 4, self.model, overlap=0.6)),
                dims=[3],
            )

            return (p1 + p2 + p3) / 3.0

    def segment_2d_slice(self, image_tensor: torch.Tensor, use_tta: bool = True) -> np.ndarray:
        """
        Segment a 2D slice by promoting to pseudo-3D.
        Args:
            image_tensor: (1, 3, H, W)
            use_tta: enable TTA (slower, more accurate)
        Returns:
            (H, W) binary mask
        """
        vol = image_tensor.unsqueeze(2).repeat(1, 1, ROI_SIZE[0], 1, 1)
        probs = self.segment_3d(vol, use_tta=use_tta)
        mid = ROI_SIZE[0] // 2
        return (probs[0, 0, mid] > 0.5).cpu().numpy().astype(np.uint8)

    def classify_from_mask(self, mask: np.ndarray) -> dict:
        lesion_pixels = int(mask.sum())
        total_pixels = int(mask.size)
        coverage = round(lesion_pixels / total_pixels * 100, 2) if total_pixels > 0 else 0.0
        return {
            "prediction": "Stroke Lesion Detected" if lesion_pixels > 0 else "No Lesion",
            "lesion_coverage_pct": coverage,
            "lesion_voxels": lesion_pixels,
        }
