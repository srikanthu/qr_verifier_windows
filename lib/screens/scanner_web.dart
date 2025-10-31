import 'package:flutter/material.dart';

class WebQRScanner extends StatefulWidget {
  const WebQRScanner({super.key});

  @override
  State<WebQRScanner> createState() => _WebQRScannerState();
}

class _WebQRScannerState extends State<WebQRScanner> {
  final TextEditingController _controller = TextEditingController();
  String _decoded = '';

  void _onSimulateScan() {
    setState(() => _decoded = _controller.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated QR scan captured')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SecureQR Web Verifier')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Web test mode:\nPaste QR payload below to simulate scan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Paste or enter SecureQR data',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Simulate QR Scan'),
              onPressed: _onSimulateScan,
            ),
            const SizedBox(height: 20),
            if (_decoded.isNotEmpty)
              Card(
                elevation: 3,
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Decoded SecureQR:\n$_decoded',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
