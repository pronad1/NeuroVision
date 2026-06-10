# server/app/ml/spine/resnet_model.py
"""
ResNet-50 for VinDr-SpineXR spine classification.

From train_resnet50.py (MICCAI 2026 paper):
    torchvision.models.resnet50(pretrained=True)
    model.fc = nn.Linear(num_features, 1)   # Binary head
    Loss: BCEWithLogitsLoss(pos_weight=normal/abnormal ratio)
    Optimizer: Adam(lr=0.001, weight_decay=0.0001)
    Scheduler: ReduceLROnPlateau(mode='max', factor=0.5, patience=3)
    Image size: 224×224

Checkpoint format: {'epoch', 'model_state_dict', 'optimizer_state_dict', 'auroc'}
Individual performance:
    AUROC: 88.88% | Sensitivity: 82.72% | Specificity: 78.13% | F1: 80.15%
"""

import torch
import torch.nn as nn
from torchvision.models import resnet50


class ResNetSpine(nn.Module):
    """
    ResNet-50 spine abnormality classifier.
    Binary output: 0 = Normal, 1 = Abnormal.

    Exact model from training:
        resnet50(pretrained=True)
        model.fc = nn.Linear(2048, 1)
    Checkpoint key: 'model_state_dict'
    """

    LABELS = ["Normal", "Abnormal"]
    IMAGE_SIZE = 224  # ResNet-50 uses 224, not 384

    def __init__(self):
        super().__init__()
        backbone = resnet50(weights=None)
        # Exact head replacement from training code:
        # num_features = model.fc.in_features  → 2048
        # model.fc = nn.Linear(num_features, 1)
        backbone.fc = nn.Linear(backbone.fc.in_features, 1)
        self.model = backbone

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, 3, 224, 224) — normalized RGB spine X-ray
        Returns:
            (B, 1) — raw logits
        """
        return self.model(x)

    def predict_proba(self, x: torch.Tensor) -> torch.Tensor:
        """Returns (B,) probability of abnormality [0, 1]."""
        return torch.sigmoid(self.forward(x)).squeeze(1)
