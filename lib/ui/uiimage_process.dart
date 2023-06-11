import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;

class ImageProcess {
  static Future<int> countPixelsInSelectedArea(Uint8List imageData, Path path) async {
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return 0;

    int pixelCount = 0;

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        if (path.contains(Offset(x.toDouble(), y.toDouble()))) {
          pixelCount++;
        }
      }
    }
    return pixelCount;
  }
}
