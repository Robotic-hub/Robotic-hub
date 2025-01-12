import 'dart:convert';

import 'package:cyborg_app/Components/Texts.dart';
import 'package:cyborg_app/Pages/ViewDocument.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cyborg_app/Components/Buttons.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FaceVerificationScreen extends StatefulWidget {
  final String email;
  final String address;
  final String stamp;

  const FaceVerificationScreen({
    Key? key,
    required this.email,
    required this.address,
    required this.stamp,
  }) : super(key: key);

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  XFile? _capturedImage;
  bool _isLoading = true;
  File? selectedfrontImage;
  File? selectedBackIdImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _pickFrontIDImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedfrontImage = File(image.path);
      });
    }
  }

  Future<void> _pickBackIDImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedBackIdImage = File(image.path);
      });
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.high);

    await _cameraController?.initialize();

    setState(() {
      _isLoading = false;
    });

    Future.delayed(const Duration(seconds: 5), () async {
      await _captureImage();
    });
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        setState(() {
          _capturedImage = image;
        });
      } catch (e) {
        print("Error capturing image: $e");
      }
    }
  }

  bool matched = false;
  // For JSON decoding
  String pdfFile = 'no url';
  Future<void> _sendImagesToApi() async {
    if (_capturedImage == null || selectedfrontImage == null) return;

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse('http://192.168.0.242:8000/verify-faces/');
    final request = http.MultipartRequest('POST', url);

    try {
      // Download the stamp file from the server
      final stampUrl =
          'http://192.168.0.242:8000${widget.stamp}'; // Adjust server URL
      final stampResponse = await http.get(Uri.parse(stampUrl));

      if (stampResponse.statusCode == 200) {
        // Save the stamp file temporarily on the device
        final tempDir = await getTemporaryDirectory();
        final stampFile = File('${tempDir.path}/stamp.jpg');
        await stampFile.writeAsBytes(stampResponse.bodyBytes);

        // Attach files to the request
        request.files.add(
          await http.MultipartFile.fromPath(
            'id_front_face',
            selectedfrontImage!.path,
          ),
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'id_back_face',
            selectedBackIdImage!.path,
          ),
        );
        request.files.add(
          await http.MultipartFile.fromPath('stamp', stampFile.path),
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'recognised_face',
            _capturedImage!.path,
          ),
        );
        request.fields['email'] = widget.email;

        final response = await request.send();

        Navigator.pop(context); // Close the loading dialog

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final responseData = jsonDecode(responseBody);

          final matchStatus = responseData['match'];

          if (matchStatus == "Matched") {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],

                    content: Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.done,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      ),
                    ),
                  ),
            );
            setState(() {
              matched = true;
              pdfFile = responseData['pdf_url'];
            });
            print('Faces match: $matchStatus');
          } else {
            print('Faces do not match: $matchStatus');
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('No Match'),
                    content: const Text('The faces do not match.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        } else {
          print('Failed to compare faces. Status code: ${response.statusCode}');
        }
      } else {
        print(
          'Failed to download stamp image. Status code: ${stampResponse.statusCode}',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print("Error sending images to API: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification'), centerTitle: true),
      backgroundColor: Theme.of(context).canvasColor,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 10,
                      child: InkWell(
                        onTap: _pickFrontIDImage,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context).canvasColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: Theme.of(context).canvasColor,
                                    ),
                                    selectedfrontImage != null
                                        ? Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10.0,
                                          ),
                                          child: Image.file(
                                            selectedfrontImage!,
                                            height: 50,
                                          ),
                                        )
                                        : Texts(
                                          color: Theme.of(context).canvasColor,
                                          text: 'Upload your front ID image',
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Card(
                      elevation: 10,
                      child: InkWell(
                        onTap: _pickBackIDImage,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context).canvasColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: Theme.of(context).canvasColor,
                                    ),
                                    selectedBackIdImage != null
                                        ? Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10.0,
                                          ),
                                          child: Image.file(
                                            selectedBackIdImage!,
                                            height: 50,
                                          ),
                                        )
                                        : Texts(
                                          color: Theme.of(context).canvasColor,
                                          text: 'Upload your back ID image',
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (selectedfrontImage != null &&
                        _capturedImage != null &&
                        selectedfrontImage != null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please look at the camera. Your photo will be captured in 5 seconds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_cameraController != null &&
                              _cameraController!.value.isInitialized)
                            SizedBox(
                              height: 200,
                              child:
                                  selectedfrontImage != null &&
                                          _capturedImage != null &&
                                          selectedfrontImage != null
                                      ? CameraPreview(_cameraController!)
                                      : Container(),
                            )
                          else
                            const Center(child: Text('Camera not available')),
                          const SizedBox(height: 20),
                        ],
                      ),
                    Column(
                      children: [
                        const Text(
                          'Captured Image:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Image.file(
                            File(
                              _capturedImage != null
                                  ? _capturedImage!.path
                                  : '',
                            ),
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),

                        matched == true
                            ? Buttons(
                              text: 'View',
                              onPressed: () {
                                print(
                                  'here is a path to the pdf file $pdfFile',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ViewDocument(pdfPath: pdfFile),
                                  ),
                                );
                              },
                              backgroundColor: Theme.of(context).canvasColor,
                              foregroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            )
                            : Buttons(
                              text: 'Verify',
                              onPressed: _sendImagesToApi,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).canvasColor,
                            ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
