import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/common.dart';

class WindowsQRScanner extends StatefulWidget {
  const WindowsQRScanner({super.key});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  CameraController? _controller;
  bool _ready = false;
  bool _decoding = false;
  String _decoded = '';
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _ready = false);
        return;
      }

      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();

      _controller!.startImageStream((CameraImage frame) async {
        if (_decoding) return;
        _decoding = true;
        await _decode(frame);
        _decoding = false;
      });

      setState(() => _ready = true);
    } catch (e) {
      debugPrint('Camera init failed: $e');
      setState(() => _ready = false);
    }
  }

  Future<void> _decode(CameraImage frame) async {
    try {
      final plane = frame.planes.first;
      final bytes = plane.bytes;

      // Build a luminance (gray) image
      final image = img.Image.fromBytes(
        frame.width,
        frame.height,
        bytes.buffer,
        numChannels: 1,
      );

      // zxing2 0.2.2 needs a List<int> of ARGB pixels
      final argbPixels = image.data; // already List<int>
      final source = RGBLuminanceSource(image.width, image.height, argbPixels);
      final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));

      final reader = QRCodeReader();
      final result = reader.decode(bitmap);

      if (result.text.isNotEmpty && result.text != _decoded) {
        setState(() => _decoded = result.text);
      }
    } catch (_) {
      // ignore decoding errors
    }
  }

  void _manual(String value) {
    setState(() => _decoded = value);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SecureQR (Windows Verifier)')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _ready
                  ? CameraPreview(_controller!)
                  : const Text(
                      'No camera detected.\nUse your USB QR reader or paste manually.',
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_ready)
                  TextField(
                    controller: _manualController,
                    onSubmitted: _manual,
                    decoration: const InputDecoration(
                      labelText: 'Scan or paste SecureQR data',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _decoded.isEmpty
                      ? 'Awaiting scan...'
                      : '✅ Decoded SecureQR:\n$_decoded',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
