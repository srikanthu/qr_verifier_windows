import 'dart:async';
import 'dart:typed_data';
import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/common.dart';

class WindowsQRScanner extends StatefulWidget {
  const WindowsQRScanner({super.key});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  CameraControllerWindows? _controller;
  bool _isCameraAvailable = false;
  String _decodedText = '';
  bool _isScanning = false;
  StreamSubscription? _frameSubscription;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCamerasWindows();
      if (cameras.isNotEmpty) {
        _isCameraAvailable = true;
        _controller = CameraControllerWindows(cameras.first);
        await _controller!.initialize();
        _startFrameStream();
        setState(() {});
      } else {
        setState(() => _isCameraAvailable = false);
      }
    } catch (e) {
      debugPrint("Camera init failed: $e");
      setState(() => _isCameraAvailable = false);
    }
  }

  void _startFrameStream() {
    if (_controller == null) return;

    _frameSubscription = _controller!.onLatestFrameStream.listen((CameraImageWindows frame) async {
      if (_isScanning) return;
      _isScanning = true;

      try {
        final buffer = frame.bytes;
        if (buffer.isNotEmpty) {
          // Convert raw bytes to grayscale image for decoding
          final imgImage = img.Image.fromBytes(
            frame.width,
            frame.height,
            Uint8List.fromList(buffer),
            format: img.Format.luminance,
          );

          final luminanceSource = RGBLuminanceSource(
              imgImage.width,
              imgImage.height,
              imgImage.getBytes(format: img.Format.luminance));

          final bitmap = BinaryBitmap(GlobalHistogramBinarizer(luminanceSource));
          final reader = QRCodeReader();
          final result = reader.decode(bitmap);
          if (result.text.isNotEmpty) {
            setState(() {
              _decodedText = result.text;
            });
          }
        }
      } catch (_) {
        // ignore failed frames
      } finally {
        _isScanning = false;
      }
    });
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _controller?.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _handleManualEntry(String value) {
    setState(() => _decodedText = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR Reader Input: $value')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureQR (Windows Verifier)'),
        actions: [
          if (_isCameraAvailable)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () async {
                await _controller?.dispose();
                await _initCamera();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isCameraAvailable
                  ? CameraPreviewWindows(_controller!)
                  : const Text(
                      'No camera found.\nYou can use a USB QR reader (keyboard input).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                if (!_isCameraAvailable)
                  TextField(
                    controller: _manualInputController,
                    decoration: const InputDecoration(
                      labelText: 'Scan or Paste QR Code Data',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleManualEntry,
                  ),
                const SizedBox(height: 10),
                Text(
                  _decodedText.isEmpty
                      ? 'Awaiting scan...'
                      : 'Decoded SecureQR:\n$_decodedText',
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
