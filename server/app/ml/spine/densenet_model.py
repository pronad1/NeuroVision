# server/app/ml/spine/densenet_model.py
"""
DenseNet-121 for VinDr-SpineXR spine classification.

From train_densenet121.py (MICCAI 2026 paper):
    timm.create_model('densenet121', pretrained=True, num_classes=1)
    Loss: BCEWithLogitsLoss(pos_weight=1.3)
    Optimizer: AdamW(lr=0.0002, weight_decay=0.01)
    Scheduler: CosineAnnealingLR(T_max=15)
    Image size: 384×384

Checkpoint format: {'epoch', 'model_state_dict', 'optimizer_state_dict', 'metrics'}
Individual performance:
    AUROC: 86.93% | Sensitivity: 80.39% | Specificity: 79.32% | F1: 79.55%
"""

import torch
import torch.nn as nn
import timm


class DenseNetSpine(nn.Module):
    """
    DenseNet-121 spine abnormality classifier.
    Binary output: 0 = Normal, 1 = Abnormal (any lesion type).

    Exact model from training:
        timm.create_model('densenet121', pretrained=False, num_classes=1)
    Checkpoint key: 'model_state_dict'
    """

    LABELS = ["Normal", "Abnormal"]
    IMAGE_SIZE = 384

    def __init__(self):
        super().__init__()
        # Exact timm call from training code (pretrained=False for inference loading)
        self.model = timm.create_model("densenet121", pretrained=False, num_classes=1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, 384, 384) — normalized RGB spine X-ray
        Returns:
            (B, 1) — raw logits (apply sigmoid for probability)
        """
        return self.model(x)

    def predict_proba(self, x: torch.Tensor) -> torch.Tensor:
        """Returns (B,) probability of abnormality [0, 1]."""
        return torch.sigmoid(self.forward(x)).squeeze(1)
