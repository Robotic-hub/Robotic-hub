import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart' show GoogleMlKit;
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class FaceVerificationScreen extends StatefulWidget {
  final dynamic imageUrl;
  final String email;
  final String address;

  const FaceVerificationScreen({
    super.key,
    required this.imageUrl,
    required this.email,
    required this.address,
  });

  @override
  _FaceVerificationScreenState createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  late CameraController _cameraController;
  final FaceMeshDetector _faceMeshDetector = FaceMeshDetector(
    option: FaceMeshDetectorOptions.faceMesh,
  );
  bool _isDetecting = false;
  List<FaceMesh> _detectedMeshes = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _meshDetector = GoogleMlKit.vision.faceMeshDetector();
    _meshPoints = [];
    _loadImageAndDetectFace();
  }

  late final FaceMeshDetector _meshDetector;
  late List<FaceMesh> _meshPoints;

  // Load the image and detect face meshes
  Future<void> _loadImageAndDetectFace() async {
    if (widget.imageUrl != null) {
      final imageFile = File(widget.imageUrl!);
      if (await imageFile.exists()) {
        final inputImage = InputImage.fromFile(imageFile);

        // Detect face meshes
        final meshes = await _meshDetector.processImage(inputImage);
        setState(() {
          _meshPoints = meshes;
        });
      }
    }
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController.initialize();

    _cameraController.startImageStream((CameraImage image) async {
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        final meshes = await processCameraImage(image);
        setState(() {
          _detectedMeshes = meshes;
        });
      } catch (e) {
        print("Error detecting face meshes: $e");
      }

      _isDetecting = false;
    });

    setState(() {});
  }

  Future<List<FaceMesh>> processCameraImage(CameraImage image) async {
    final inputImage = convertCameraImageToInputImage(image, _cameraController);
    return await _faceMeshDetector.processImage(inputImage);
  }

  InputImage convertCameraImageToInputImage(
    CameraImage image,
    CameraController controller,
  ) {
    // Combine all the planes into one byte array
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final Uint8List allBytes = buffer.done().buffer.asUint8List();

    // Set image size
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Set image rotation based on the camera's orientation
    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(
          controller.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    // Set the image format (e.g., NV21 or YUV420_888)
    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Map plane data (metadata)
    // final List<InputImagePlaneMetadata> planeData = image.planes.map((Plane plane) {
    //   return InputImagePlaneMetadata(
    //     bytesPerRow: plane.bytesPerRow,
    //     height: plane.height,
    //     width: plane.width,
    //   );
    // }).toList();

    // Create and return the InputImage
    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow:
            image
                .planes
                .first
                .bytesPerRow, // Ensure correct bytes per row for the first plane
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceMeshDetector.close();
    _meshDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 10,
        title: const Text('Face Verification'),
        foregroundColor: Theme.of(context).canvasColor,
        backgroundColor: Theme.of(context).primaryColorDark,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Image.file(
            widget.imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Center(child: CameraPreview(_cameraController)),
          // if (_detectedMeshes.isNotEmpty)
          //   CustomPaint(
          //     painter: FaceMeshPainter(_detectedMeshes),
          //     child: Container(),
          //   ),
        ],
      ),
    );
  }
}

class FaceMeshPainter extends CustomPainter {
  final List<FaceMesh> meshPoints;

  FaceMeshPainter(this.meshPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke;

    for (var mesh in meshPoints) {
      for (var point in mesh.points) {
        canvas.drawCircle(
          Offset(point.x.toDouble(), point.y.toDouble()),
          2.0,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
