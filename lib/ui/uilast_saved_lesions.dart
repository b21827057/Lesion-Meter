import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

String decodeUrl(String url) {
  return Uri.decodeComponent(url);
}

class LastSavedLesions extends StatefulWidget {
  final String patientId;

  const LastSavedLesions({Key? key, required this.patientId}) : super(key: key);

  get lastGuestImageDateTime => null;

  @override
  _LastSavedLesionsState createState() => _LastSavedLesionsState();
}

class _LastSavedLesionsState extends State<LastSavedLesions> {
  bool showEditButton = false;
  Map<String, List<String>> downloadedImageData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.patientId.isNotEmpty) {
      retrieveImagesFromFirebase();
    }
  }

  Future<void> retrieveImagesFromFirebase() async {
    try {
      final ListResult listResult = await FirebaseStorage.instance.ref().child(widget.patientId).listAll();
      final List<Reference> folderRefs = listResult.prefixes;

      // sort by date time.
      folderRefs.sort((a, b) => DateFormat('dd.MM.yyyy HH:mm:ss').parse(b.name).compareTo(DateFormat('dd.MM.yyyy HH:mm:ss').parse(a.name)));

      for (final Reference folderRef in folderRefs) {
        final ListResult imageResult = await folderRef.listAll();
        final List<Reference> imageRefs = imageResult.items;
        List<String> fileUrlList = [];
        for (final Reference ref in imageRefs) {
          final String downloadUrl = await ref.getDownloadURL();
          fileUrlList.add(downloadUrl);
        }
        downloadedImageData[folderRef.name] = fileUrlList;
      }
      setState(() {
        isLoading = false;  // İşlem tamamlandığında, durumu güncelle
      });
    } catch (e) {
      setState(() {
        isLoading = false;  // Hata durumunda da durumu güncelle
      });
      print('Firebase Storage retrieval error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: downloadedImageData.length,
        itemBuilder: (context, index) {
          final folderName = downloadedImageData.keys.elementAt(index);
          final imageUrls = downloadedImageData[folderName];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                folderName + ' cm²',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                shrinkWrap: true,
                physics: ScrollPhysics(),
                itemCount: imageUrls?.length ?? 0,
                itemBuilder: (context, innerIndex) {
                  final imageUrl = imageUrls?[innerIndex] ?? '';

                  return imageUrl.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return DetailScreen(imageUrl: imageUrl, appText: folderName);
                      }));
                    },
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String imageUrl;
  final String appText;

  DetailScreen({required this.imageUrl, required this.appText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appText),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
          minScale: 1.0,
          maxScale: 2.0,
          boundaryMargin: EdgeInsets.all(100),
        ),
      ),
    );
  }
}