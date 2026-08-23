import sys

sys.path.append("/app")

from ml.predict import predict_image


def detect_pothole(image):

    result = predict_image(
        image
    )

    return result
