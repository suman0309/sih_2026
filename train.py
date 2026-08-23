import os

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import DenseNet121
from tensorflow.keras.preprocessing.image import ImageDataGenerator


IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 15

TRAIN_DIR = "data/train"
VALID_DIR = "data/valid"
MODEL_PATH = "ml/models/pothole_model.keras"


def create_model():
    base_model = DenseNet121(
        weights="imagenet",
        include_top=False,
        input_shape=(224, 224, 3)
    )

    # Freeze pretrained layers initially
    base_model.trainable = False

    model = models.Sequential([
        base_model,

        layers.GlobalAveragePooling2D(),

        layers.Dropout(0.3),

        layers.Dense(
            128,
            activation="relu"
        ),

        layers.Dropout(0.2),

        layers.Dense(
            1,
            activation="sigmoid"
        )
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(
            learning_rate=0.0001
        ),
        loss="binary_crossentropy",
        metrics=["accuracy"]
    )

    return model


def train_model():

    train_generator = ImageDataGenerator(
        rescale=1.0 / 255,
        rotation_range=15,
        width_shift_range=0.1,
        height_shift_range=0.1,
        zoom_range=0.1,
        horizontal_flip=True
    )

    valid_generator = ImageDataGenerator(
        rescale=1.0 / 255
    )

    train_data = train_generator.flow_from_directory(
        TRAIN_DIR,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="binary"
    )

    valid_data = valid_generator.flow_from_directory(
        VALID_DIR,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="binary"
    )

    model = create_model()

    os.makedirs(
        os.path.dirname(MODEL_PATH),
        exist_ok=True
    )

    model.fit(
        train_data,
        validation_data=valid_data,
        epochs=EPOCHS
    )

    model.save(MODEL_PATH)

    print("Model saved:", MODEL_PATH)


if __name__ == "__main__":
    train_model()
