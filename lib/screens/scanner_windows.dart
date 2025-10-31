import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';

class WindowsQRScanner extends StatefulWidget {
  const WindowsQRScanner({super.key});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  CameraController? _controller;
  String? qrResult;
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => qrResult = "No cameras found");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();

      setState(() => scanning = true);
      _startScanLoop();
    } catch (e) {
      setState(() => qrResult = "Camera init failed: $e");
    }
  }

  Future<void> _startScanLoop() async {
    final reader = QRCodeReader();

    while (scanning && mounted) {
      try {
        final picture = await _controller!.takePicture();
        final bytes = await picture.readAsBytes();

        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        final width = decoded.width;
        final height = decoded.height;

        // Get raw RGBA bytes (no named parameters)
        final pixels = decoded.getBytes();

        // Convert 4-byte RGBA data to Int32 list
        final intCount = Uint8List.fromList(pixels)
            .buffer
            .asInt32List(0, pixels.length ~/ 4);

        final luminance = RGBLuminanceSource(width, height, intCount);
        final bitmap = BinaryBitmap(GlobalHistogramBinarizer(luminance));

        try {
          final result = reader.decode(bitmap);
          if (result != null && result.text.isNotEmpty) {
            setState(() {
              qrResult = result.text;
              scanning = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("QR Detected: ${result.text}")),
            );
          }
        } catch (_) {
          // ignore if no QR found in this frame
        }
      } catch (_) {
        // ignore camera or decode errors, continue loop
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SecureQR (Windows Verifier)")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              child: _controller?.value.isInitialized ?? false
                  ? CameraPreview(_controller!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  qrResult ?? "Scanning...",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
