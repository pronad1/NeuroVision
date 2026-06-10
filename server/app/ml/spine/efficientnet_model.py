# server/app/ml/spine/efficientnet_model.py
"""
EfficientNetV2-S for VinDr-SpineXR spine classification.

From train_efficientnet.py (MICCAI 2026 paper):
    timm.create_model('tf_efficientnetv2_s', pretrained=True, num_classes=1)
    Loss: BCEWithLogitsLoss(pos_weight=normal/abnormal ratio)
    Optimizer: AdamW(lr=0.0003, weight_decay=0.05)
    Scheduler: CosineAnnealingLR(T_max=60, eta_min=1e-6)
    Image size: 384×384
    Augmentation: MixUp(alpha=0.2) + RandomErasing

Checkpoint format: {'epoch', 'model_state_dict', 'optimizer_state_dict', ...}
Individual performance:
    AUROC: 89.44% | Sensitivity: 70.80% | Specificity: 91.12% | F1: 79.34%
"""

import torch
import torch.nn as nn
import timm


class EfficientNetSpine(nn.Module):
    """
    EfficientNetV2-S spine abnormality classifier.
    Binary output: 0 = Normal, 1 = Abnormal.

    Exact model from training:
        timm.create_model('tf_efficientnetv2_s', pretrained=False, num_classes=1)
    Checkpoint key: 'model_state_dict'
    """

    LABELS = ["Normal", "Abnormal"]
    IMAGE_SIZE = 384

    def __init__(self):
        super().__init__()
        # Exact timm call from training code
        self.model = timm.create_model("tf_efficientnetv2_s", pretrained=False, num_classes=1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, 384, 384) — normalized RGB spine X-ray
        Returns:
            (B, 1) — raw logits
        """
        return self.model(x)

    def predict_proba(self, x: torch.Tensor) -> torch.Tensor:
        """Returns (B,) probability of abnormality [0, 1]."""
        return torch.sigmoid(self.forward(x)).squeeze(1)
