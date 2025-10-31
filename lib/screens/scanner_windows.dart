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
  bool _isCameraReady = false;
  bool _decoding = false;
  String _decoded = '';
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isCameraReady = false);
        return;
      }

      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();

      _controller!.startImageStream((CameraImage frame) async {
        if (_decoding) return;
        _decoding = true;
        await _decodeFrame(frame);
        _decoding = false;
      });

      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera init failed: $e');
      setState(() => _isCameraReady = false);
    }
  }

  Future<void> _decodeFrame(CameraImage frame) async {
    try {
      final plane = frame.planes.first;
      final bytes = plane.bytes;

      // Correct Image.fromBytes syntax for image 4.2.0+
      final image = img.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: Uint8List.fromList(bytes),
        numChannels: 1, // grayscale
      );

      final luminanceSource = RGBLuminanceSource(
        image.width,
        image.height,
        image.getBytes(format: img.Format.rgb888),
      );

      final bitmap = BinaryBitmap(GlobalHistogramBinarizer(luminanceSource));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);

      if (result.text.isNotEmpty && result.text != _decoded) {
        setState(() => _decoded = result.text);
      }
    } catch (_) {
      // Ignore bad frames
    }
  }

  void _onManualInput(String value) {
    setState(() => _decoded = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manual input: $value')),
    );
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
              child: _isCameraReady
                  ? CameraPreview(_controller!)
                  : const Text(
                      'No camera detected.\nYou can use your USB QR reader (keyboard input).',
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_isCameraReady)
                  TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      labelText: 'Scan or paste SecureQR data',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _onManualInput,
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
