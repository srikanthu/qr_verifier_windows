import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/common.dart';

class WindowsQRScanner extends StatefulWidget {
  const WindowsQRScanner({super.key});

  @override
  State<WindowsQRScanner> createState() => _WindowsQRScannerState();
}

class _WindowsQRScannerState extends State<WindowsQRScanner> {
  late final CameraWindows _camera;
  StreamSubscription<CameraImageWindows>? _frameSub;
  bool _cameraReady = false;
  bool _decoding = false;
  String _decoded = '';
  final _usbInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCamerasWindows();
      if (cameras.isEmpty) {
        setState(() => _cameraReady = false);
        return;
      }

      _camera = CameraWindows(cameras.first);
      await _camera.initialize();
      setState(() => _cameraReady = true);

      _frameSub = _camera.onLatestFrameStream.listen((frame) {
        if (_decoding) return;
        _decoding = true;
        _decodeFrame(frame);
      });
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      setState(() => _cameraReady = false);
    }
  }

  Future<void> _decodeFrame(CameraImageWindows frame) async {
    try {
      final bytes = Uint8List.fromList(frame.bytes);
      final image = img.Image.fromBytes(frame.width, frame.height, bytes);
      final luminanceSource = RGBLuminanceSource(
          image.width, image.height, image.getBytes(format: img.Format.rgb));
      final bitmap = BinaryBitmap(GlobalHistogramBinarizer(luminanceSource));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);

      if (result.text.isNotEmpty && result.text != _decoded) {
        setState(() => _decoded = result.text);
      }
    } catch (_) {
      // ignore invalid frame
    } finally {
      _decoding = false;
    }
  }

  void _onUSBInput(String value) {
    setState(() => _decoded = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR Reader Input: $value')),
    );
  }

  @override
  void dispose() {
    _frameSub?.cancel();
    _camera.dispose();
    _usbInputController.dispose();
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
              child: _cameraReady
                  ? CameraPreviewWindows(_camera)
                  : const Text(
                      'No webcam detected.\nPlease use your USB QR reader instead.',
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (!_cameraReady)
                  TextField(
                    controller: _usbInputController,
                    decoration: const InputDecoration(
                      labelText: 'Scan or paste SecureQR data',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _onUSBInput,
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
