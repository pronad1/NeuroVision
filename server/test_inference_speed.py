import io
import time
import torch
from PIL import Image
from app.core.model_registry import ModelRegistry
from app.ml.inference import classify_brain, classify_spine, classify_chest, classify_heart

def create_mock_image_bytes():
    img = Image.new("RGB", (224, 224), color="white")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()

def main():
    print("Testing CPU Inference Speed...")
    torch.set_num_threads(2)
    print("Loading models...")
    ModelRegistry.load_all()
    print("Models loaded.")

    img_bytes = create_mock_image_bytes()

    # 1. Test Brain MRI Single Model vs Ensemble
    print("\n--- Brain MRI Inference ---")
    start = time.time()
    res = classify_brain(img_bytes, model_name="DERNet")
    print(f"DERNet Single Model Time: {time.time() - start:.2f}s")
    print(f"Result keys: {list(res.keys())}")
    print(f"Prediction: {res['prediction']}, Coverage: {res.get('lesion_coverage_pct')}%")

    start = time.time()
    res = classify_brain(img_bytes)
    print(f"Ensemble (DERNet+SegResNet+AttentionUNet) Time: {time.time() - start:.2f}s")
    print(f"Prediction: {res['prediction']}, Coverage: {res.get('lesion_coverage_pct')}%")

    # 2. Test Spine MRI
    print("\n--- Spine MRI Inference ---")
    start = time.time()
    res = classify_spine(img_bytes, model_name="ResNet50")
    print(f"ResNet50 Single Model Time: {time.time() - start:.2f}s")
    print(f"Result keys: {list(res.keys())}")
    print(f"Prediction: {res['prediction']}")

    start = time.time()
    res = classify_spine(img_bytes)
    print(f"Ensemble (DenseNet+EfficientNet+ResNet50) Time: {time.time() - start:.2f}s")
    print(f"Prediction: {res['prediction']}")

    # 3. Test Chest X-Ray
    print("\n--- Chest X-Ray Inference (Single Forward Pass Grad-CAM) ---")
    start = time.time()
    res = classify_chest(img_bytes)
    print(f"Chest X-Ray Time: {time.time() - start:.2f}s")
    print(f"Result keys: {list(res.keys())}")
    print(f"Prediction: {res['prediction']}")

    # 4. Test Heart Echo
    print("\n--- Heart Echo Inference (Single Forward Pass Grad-CAM) ---")
    start = time.time()
    res = classify_heart(img_bytes)
    print(f"Heart Echo Time: {time.time() - start:.2f}s")
    print(f"Result keys: {list(res.keys())}")
    print(f"Prediction: {res['prediction']}")

if __name__ == "__main__":
    main()
