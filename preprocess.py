from PIL import Image


IMAGE_SIZE = (224, 224)


def prepare_image(image):

    image = image.convert(
        "RGB"
    )

    image = image.resize(
        IMAGE_SIZE
    )

    return image
