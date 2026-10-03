from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import uvicorn
import numpy as np
import json
from pathlib import Path

app = FastAPI(title="ORIA ML Inference Server")

# Paths
MODEL_PATH = Path("/home/grace/hackaton/model_output_synthetic/model_synthetic.joblib")
SCHEMA_PATH = Path("/home/grace/hackaton/model_output_synthetic/preprocessing_schema.json")

# Load model and schema once at startup
if not MODEL_PATH.exists():
    print(f"CRITICAL ERROR: Model file not found at {MODEL_PATH}")
    # We don't exit here so the server can still start, but predictions will fail
else:
    model = joblib.load(MODEL_PATH)

if SCHEMA_PATH.exists():
    with open(SCHEMA_PATH, "r") as f:
        schema = json.load(f)
else:
    schema = None

class PredictionRequest(BaseModel):
    # Use a flexible dict to handle potential variations in features
    # But we'll validate against schema.json
    features: dict

@app.get("/health")
def health():
    return {"status": "healthy", "model_loaded": MODEL_PATH.exists()}

@app.post("/predict")
async def predict(request: PredictionRequest):
    if not MODEL_PATH.exists():
        raise HTTPException(status_code=500, detail="Model file not loaded on server")

    try:
        # 1. Create DataFrame from features
        df = pd.DataFrame([request.features])

        # 2. Ensure all required columns from schema are present (fill with NaN if missing)
        if schema:
            all_required = schema["numeric_features"] + schema["categorical_features"]
            for col in all_required:
                if col not in df.columns:
                    df[col] = np.nan

        # 3. Inference
        # The scikit-learn pipeline handles imputer and scaler internally
        prediction = model.predict(df)[0]

        # Get probability for the positive class (ADMIS = 1)
        probabilities = model.predict_proba(df)[0]
        prob_admis = probabilities[1] if len(probabilities) > 1 else 0.0

        return {
            "prediction": "ADMIS" if prediction == 1 else "RECALE",
            "probability": round(float(prob_admis), 3),
            "model_mode": "synthetic_test",
            "warning": "Cette prédiction est basée sur des données synthétiques et ne constitue pas une décision officielle."
        }
    except Exception as e:
        print(f"Inference error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

if __name__ == "__main__":
    # Bind to localhost for security as per internal guidelines
    uvicorn.run(app, host="127.0.0.1", port=8000)
