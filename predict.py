import numpy as np
import tensorflow as tf

from PIL import Image


MODEL_PATH = "ml/models/pothole_model.keras"

model = tf.keras.models.load_model(
    MODEL_PATH
)


def predict_image(image):

    image = image.convert("RGB")

    image = image.resize(
        (224, 224)
    )

    image_array = np.array(
        image,
        dtype=np.float32
    )

    image_array = image_array / 255.0

    image_array = np.expand_dims(
        image_array,
        axis=0
    )

    probability = float(
        model.predict(
            image_array,
            verbose=0
        )[0][0]
    )

    if probability >= 0.5:
        label = "pothole"
        confidence = probability
    else:
        label = "normal_road"
        confidence = 1 - probability

    return {
        "label": label,
        "confidence": round(
            confidence,
            4
        )
    }
