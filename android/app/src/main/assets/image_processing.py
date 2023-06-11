import cv2
import numpy as np
from chaquopy.shim import JavaException
from chaquopy_java_interface import ShimJavaInterface, java

class ImageProcessing(ShimJavaInterface):

    def process_image(self, image_path: str, threshold_value: int):
        try:
            # Load the image
            image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

            # Threshold the image
            _, thresholded = cv2.threshold(image, threshold_value, 255, cv2.THRESH_BINARY)

            # Count white and black pixels
            white_pixels = np.sum(thresholded == 255)
            black_pixels = np.sum(thresholded == 0)

            return [white_pixels, black_pixels]

        except Exception as e:
            raise JavaException(java.Exception(str(e)))

def initialize():
    return ImageProcessing()
