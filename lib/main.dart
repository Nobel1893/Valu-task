import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv/core/core.dart';
import 'package:opencv/opencv.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  dynamic res;
  late XFile file;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await OpenCV.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> detectObject(Uint8List bvtes) async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      res = await ImgProc.blur(bvtes, [45, 45], [20, 30], Core.borderReflect);
//        imageNew = Image.memory(res);
      setState(() {
        postProcessing = res;
      });
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                preproccessing = null;
                postProcessing = null;
              });
            },
            child: Icon(Icons.refresh),
          ),
          body: Column(
            children: [
              Expanded(
                  child: Container(
                      child: preproccessing == null
                          ? CameraWidget(onImageCapture)
                          : Center(
                              child: Image.memory(preproccessing!),
                            ))),
              Expanded(
                child: Container(
                    child: postProcessing != null
                        ? Center(child: Image.memory(postProcessing!))
                        : Container()),
              ),
            ],
          )),
    );
  }

  Uint8List? preproccessing;
  Uint8List? postProcessing;

  void onImageCapture(XFile file) async {
    this.file = file;
    var bytes = await file.readAsBytes();

//    final bytes = await File(file.path).readAsBytes();
    setState(() {
      preproccessing = bytes;
    });
    detectObject(bytes);
  }
}

class CameraWidget extends StatefulWidget {
  Function onImageCapture;

  CameraWidget(this.onImageCapture, {Key? key}) : super(key: key);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return Container(
      height: 360,
      child: Stack(
        children: [
          CameraPreview(controller),
          FloatingActionButton(
            onPressed: () async {
              widget.onImageCapture(await controller.takePicture());
            },
            child: Icon(Icons.camera),
          )
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        //onNewCameraSelected(controller.description);
      }
    }
  }
}
