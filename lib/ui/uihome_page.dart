import 'uilast_saved_lesions.dart';
import 'uicamera_screen.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:core';

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;
  final String patientId;

  MyHomePage({
    Key? key,
    required this.camera,
    required this.patientId,
  }) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static MyHomePageState of(BuildContext context) {
    return context.findAncestorStateOfType<MyHomePageState>()!;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient: ${widget.patientId}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'New Lesion'),
            Tab(text: 'Last Saved Lesions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CameraScreen(camera: widget.camera, patientId: widget.patientId),
          LastSavedLesions(patientId: widget.patientId),
        ],
      ),
    );
  }
}
