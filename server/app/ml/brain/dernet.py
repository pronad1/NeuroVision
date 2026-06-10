# server/app/ml/brain/dernet.py
"""
DERNet — EXACT architecture from training code.

From DERNet.ipynb (ISLES-2022 stroke lesion segmentation):
    DERNet(in_c=3, out_c=1, f=(32, 64, 128))

Sub-modules (verbatim from notebook):
  - LSCBlock:    Multi-scale conv encoder (3×3 + 5×5 + 7×7) with InstanceNorm + GELU
  - BiMambaSim:  Bidirectional GRU bottleneck simulating Mamba-style SSM
  - BAGF:        Boundary-Aware Gated Fusion for skip connections

Input:  (B, 3, D, H, W) — 3D volumetric (DWI + ADC + FLAIR)
Output: (B, 1, D, H, W) — binary stroke lesion segmentation logits
Best val Dice: 0.8171  |  Test Dice: ~0.81
"""

import torch
import torch.nn as nn
import numpy as np

from monai.inferers import sliding_window_inference

ROI_SIZE = (64, 64, 64)


# ── Exact sub-modules from DERNet.ipynb ──────────────────────────────────────

class LSCBlock(nn.Module):
    """
    Large-Scale Conv Block — multi-scale feature extraction.
    Splits channels across 3×3, 5×5, and 7×7 convolutions, then
    concatenates → InstanceNorm3d → GELU.
    """
    def __init__(self, in_c: int, out_c: int):
        super().__init__()
        self.c3 = nn.Conv3d(in_c, out_c // 3, 3, padding=1)
        self.c5 = nn.Conv3d(in_c, out_c // 3, 5, padding=2)
        self.c7 = nn.Conv3d(in_c, out_c - 2 * (out_c // 3), 7, padding=3)
        self.bn = nn.InstanceNorm3d(out_c)
        self.ac = nn.GELU()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.ac(self.bn(torch.cat([self.c3(x), self.c5(x), self.c7(x)], dim=1)))


class BiMambaSim(nn.Module):
    """
    Bidirectional Mamba Simulator — uses BiGRU to approximate SSM bottleneck.
    Operates on flattened spatial tokens, then reshapes back to 3D.
    """
    def __init__(self, c: int):
        super().__init__()
        self.gru = nn.GRU(c, max(1, c // 2), batch_first=True, bidirectional=True)
        self.nm = nn.LayerNorm(c)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        B, C, D, H, W = x.shape
        s, _ = self.gru(x.view(B, C, -1).permute(0, 2, 1))   # (B, D*H*W, C)
        return self.nm(s).permute(0, 2, 1).view(B, C, D, H, W) + x


class BAGF(nn.Module):
    """
    Boundary-Aware Gated Fusion — combines encoder skip (e) and decoder (d).
    Spatial attention on e, channel attention on d, fused via 1×1 conv.
    """
    def __init__(self, c: int):
        super().__init__()
        self.sg = nn.Conv3d(c, 1, 1)                                       # spatial gate
        self.cg = nn.Sequential(
            nn.AdaptiveAvgPool3d(1), nn.Conv3d(c, c, 1), nn.Sigmoid()      # channel gate
        )
        self.fs = nn.Conv3d(c * 2, c, 1)                                   # fusion

    def forward(self, e: torch.Tensor, d: torch.Tensor) -> torch.Tensor:
        return self.fs(torch.cat([
            e * torch.sigmoid(self.sg(e)),
            d * self.cg(d),
        ], dim=1))


# ── Main DERNet ───────────────────────────────────────────────────────────────

class DERNet(nn.Module):
    """
    Dual-Encoder Residual-style segmentation network.

    Exact config from DERNet.ipynb:
        DERNet(in_c=3, out_c=1, f=(32, 64, 128))

    Architecture:
        Encoder: 3 × LSCBlock + MaxPool3d
        Bottleneck: BiMambaSim (bidirectional GRU SSM approximation)
        Decoder: 2 × ConvTranspose3d upsampling + BAGF skip fusion + LSCBlock
        Head: Conv3d(f[0], 1, 1)
    """

    TASK = "Stroke Lesion Segmentation (ISLES-2022)"
    MODALITIES = ["DWI", "ADC", "FLAIR"]

    def __init__(self, in_c: int = 3, out_c: int = 1, f: tuple = (32, 64, 128)):
        super().__init__()
        # Encoder
        self.e1 = LSCBlock(in_c, f[0])
        self.e2 = LSCBlock(f[0], f[1])
        self.e3 = LSCBlock(f[1], f[2])
        self.dn = nn.MaxPool3d(2)
        # Bottleneck
        self.bt = BiMambaSim(f[2])
        # Decoder upsampling
        self.u2 = nn.ConvTranspose3d(f[2], f[1], 2, stride=2)
        self.u1 = nn.ConvTranspose3d(f[1], f[0], 2, stride=2)
        # Skip fusion + refinement
        self.f2 = BAGF(f[1])
        self.d2 = LSCBlock(f[1], f[1])
        self.f1 = BAGF(f[0])
        self.d1 = LSCBlock(f[0], f[0])
        # Output head
        self.fn = nn.Conv3d(f[0], out_c, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, D, H, W)
        Returns:
            (B, 1, D, H, W) — raw logits
        """
        x1 = self.e1(x)
        x2 = self.e2(self.dn(x1))
        x3 = self.e3(self.dn(x2))
        b  = self.bt(x3)
        y2 = self.d2(self.f2(x2, self.u2(b)))
        y1 = self.d1(self.f1(x1, self.u1(y2)))
        return self.fn(y1)

    # ── Inference helpers ─────────────────────────────────────────────────────

    def segment_3d(self, volume: torch.Tensor) -> torch.Tensor:
        """
        Sliding-window 3D segmentation (same as training validation loop).
        Args:
            volume: (1, 3, D, H, W)
        Returns:
            (1, 1, D, H, W) — probability map [0, 1]
        """
        self.eval()
        with torch.no_grad():
            logits = sliding_window_inference(
                volume, ROI_SIZE, sw_batch_size=4,
                predictor=self, overlap=0.6
            )
            return torch.sigmoid(logits)

    def segment_2d_slice(self, image_tensor: torch.Tensor) -> np.ndarray:
        """
        Promote a 2D image slice to pseudo-3D and segment.
        Args:
            image_tensor: (1, 3, H, W)
        Returns:
            (H, W) binary lesion mask
        """
        vol = image_tensor.unsqueeze(2).repeat(1, 1, ROI_SIZE[0], 1, 1)
        probs = self.segment_3d(vol)
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
