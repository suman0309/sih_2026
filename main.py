from fastapi import FastAPI

from app.routes.prediction import (
    router as prediction_router
)


app = FastAPI(
    title="SIH Pothole Detection API",
    version="1.0.0"
)


app.include_router(
    prediction_router
)


@app.get("/")
def home():

    return {
        "message": "Pothole Detection API is running"
    }


@app.get("/health")
def health():

    return {
        "status": "healthy"
    }
