import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'uiimage_process.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'uihome_page.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String patientId;

  const CameraScreen({
    Key? key,
    required this.camera,
    required this.patientId,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<Offset> _points = [];
  List<File> _images = [];
  double totalLesionArea = 0.0;
  int totalImages = 0;

  late Rect boundingBox;
  late double cardWidth;
  late double cardHeight;
  double _pixelCm2Value = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      RenderBox object = context.findRenderObject() as RenderBox;
      Offset _localPosition = object.globalToLocal(details.globalPosition);
      _points = List.from(_points)..add(_localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    cardWidth = screenWidth * (4 / 5);
    cardHeight = (cardWidth / 85.6) * 53.98;

    boundingBox = Rect.fromLTWH(
      (screenWidth - cardWidth) / 2,
      screenHeight * 0.1,
      cardWidth,
      cardHeight,
    );

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned.fromRect(
                  rect: boundingBox,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2.0),
                    ),
                  ),
                ),
                GestureDetector(
                  onPanUpdate: _handlePanUpdate,
                  child: CustomPaint(painter: SelectionPainter(_points)),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "btn1",
              onPressed: () async {
                await takeAndProcessPicture();
              },
              child: Icon(Icons.camera_alt),
            ),
            SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              heroTag: "btn2",
              onPressed: () {
                final strLesionArea = totalLesionArea.toStringAsFixed(2);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Total Lesion Area'),

                      content: Text('Total Lesion Area: $strLesionArea cm^2 in $totalImages images.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            uploadFile(_images, strLesionArea, widget.patientId).then((_)
                            {
                              _images.clear();
                            });
                            totalLesionArea=0;
                            totalImages=0;
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.done),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takeAndProcessPicture() async {
    final image = await _controller.takePicture();
    final imageFile = File(image.path);
    _images.add(imageFile);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.zero,
          buttonPadding: EdgeInsets.zero,
          content: Stack(
            children: [
              Container(
                width: double.maxFinite,
                height: double.maxFinite,
                child: GestureDetector(
                  onPanUpdate: _handlePanUpdate,
                  child: Stack(
                    children: [
                      Transform.scale(
                        scale: 1,
                        child: Image.file(imageFile),
                      ),
                      CustomPaint(
                        painter: SelectionPainter(_points),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processSelectedArea(imageFile);
                    },
                    child: Text('OK'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processSelectedArea(File imageFile) async {
    Uint8List imageData = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return;

    img.Image croppedImage = img.copyCrop(
      image,
      boundingBox.left.toInt(),
      boundingBox.top.toInt(),
      boundingBox.width.toInt(),
      boundingBox.height.toInt(),
    );

    int pixelCount = croppedImage.length;
    _pixelCm2Value = 8.56*5.398 / pixelCount; // 1 pixelin cm^2 karşılığı

    // path oluşturma
    Path path = Path();
    path.addPolygon(_points.where((element) => element != null).toList(), true);

    int selectedPixelCount = await ImageProcess.countPixelsInSelectedArea(imageData, path);

    double lesionArea = selectedPixelCount * _pixelCm2Value; // Lezyon alanı
    totalLesionArea += lesionArea;
    totalImages++;

    showDialog(
      context: context,
      builder: (context) {
        final strLesionArea = lesionArea.toStringAsFixed(2);
        return AlertDialog(
          title: Text('Lesion Area'),
          content: Text('Lesion Area: $strLesionArea cm^2'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _pixelCm2Value = 0; // Sonraki hesaplamalar için sıfırla
                  _points.clear(); // Çizilen çizgileri temizle
                });
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Next Step'),
                      content: Text('Please take another picture from a different angle.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

}

class SelectionPainter extends CustomPainter {
  final List<Offset> points;
  SelectionPainter(this.points) : super();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.teal
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) => oldDelegate.points != points;
}


uploadFile(List<File> images, String surfaceArea, String patientId) async {
  /* Create path str. */
  final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
  final formattedTime = dateFormat.format(DateTime.now());

  final path = '$patientId/$formattedTime Lesion S. Area: $surfaceArea';

  final storage = FirebaseStorage.instance;

  for (int i=0; i < images.length; ++i) {
    final ref = storage.ref().child('$path/$i.jpg');
    await ref.putFile(images[i]);
  }
}
