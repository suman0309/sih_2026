from fastapi import (
    APIRouter,
    File,
    UploadFile,
    HTTPException
)

from PIL import Image

from app.services.ml_service import (
    detect_pothole
)


router = APIRouter(
    prefix="/api",
    tags=["Pothole Detection"]
)


@router.post("/detect")
async def detect(
    file: UploadFile = File(...)
):

    if not file.content_type.startswith(
        "image/"
    ):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image."
        )

    try:

        image = Image.open(
            file.file
        )

        result = detect_pothole(
            image
        )

        return {
            "filename": file.filename,
            "result": result
        }

    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=str(error)
        )
