import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class WebQRScanner extends StatefulWidget {
  const WebQRScanner({super.key});

  @override
  State<WebQRScanner> createState() => _WebQRScannerState();
}

class _WebQRScannerState extends State<WebQRScanner> {
  String? qrResult;
  bool scanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SecureQR (Web Scanner)')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: scanning
                  ? QRCodeDartScanView(
                      scanInvertedQRCode: true,
                      typeScan: TypeScan.live,
                      onCapture: (Result result) {
                        setState(() {
                          qrResult = result.text;
                          scanning = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('QR Detected: ${result.text}')),
                        );
                      },
                    )
                  : const Center(child: Text('Scan completed or stopped')),
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
                  qrResult ?? "Show QR to webcam...",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (!scanning)
            ElevatedButton.icon(
              onPressed: () => setState(() => scanning = true),
              icon: const Icon(Icons.restart_alt),
              label: const Text("Restart Scanner"),
            ),
        ],
      ),
    );
  }
}
