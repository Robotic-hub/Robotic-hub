import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show ByteData, NetworkAssetBundle, Uint8List;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDocument extends StatefulWidget {
  final String pdfPath;

  const ViewDocument({Key? key, required this.pdfPath}) : super(key: key);

  @override
  _ViewDocument createState() => _ViewDocument();
}

class _ViewDocument extends State<ViewDocument> {
  PdfDocument? _pdfDocument;
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    String path = widget.pdfPath;

    // Check if the path is from Windows (with C: drive)
    if (Platform.isAndroid) {
      path = path.replaceAll("/media/", "file://"); // Convert to file URI
      path = path.replaceAll(
        "%3A",
        ":",
      ); // Decode any percent-encoded characters like '%3A' to ':'
    } else {
      // For mobile devices, assume the path is a local file path
      path = 'file://$path';
    }

    try {
      final ByteData data = await NetworkAssetBundle(Uri.parse(path)).load("");
      _pdfBytes = data.buffer.asUint8List();
      _pdfDocument = PdfDocument(inputBytes: _pdfBytes);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  void _downloadPdf() async {
    String pdfUrl = widget.pdfPath;
    // Ensure to prefix 'file://' for local files to avoid errors
    pdfUrl = pdfUrl.startsWith('file://') ? pdfUrl : 'file://$pdfUrl';

    if (await canLaunch(pdfUrl)) {
      await launch(pdfUrl);
    } else {
      throw 'Could not launch $pdfUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        title: Text('View ID'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.download), onPressed: _downloadPdf),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SfPdfViewer.file(
                File(widget.pdfPath),
                scrollDirection: PdfScrollDirection.vertical,
              ),
    );
  }
}
