import 'dart:typed_data';

import 'ui/uimenu.dart';
import 'ui/uiimage_process.dart';
import 'ui/uilast_saved_lesions.dart';
import 'ui/uicamera_screen.dart';
import 'ui/uihome_page.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'dart:core';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MyApp({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      navigatorKey: navigatorKey,
      home: MenuPage(onSubmit: (value) {
        // Menüden gelen değeri alıp ana sayfaya geçiş yap
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MyHomePage(camera: camera, patientId: value),
          ),
        );
      }), // MenuPage
    );
  }
}
