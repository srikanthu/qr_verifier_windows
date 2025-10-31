import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/scanner_windows.dart';
import 'screens/scanner_web.dart';

void main() {
  runApp(const SecureQRVerifierApp());
}

class SecureQRVerifierApp extends StatelessWidget {
  const SecureQRVerifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureQR Verifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PlatformSelector(),
    );
  }
}

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const WebQRScanner();
    if (Platform.isWindows) return const WindowsQRScanner();
    return Scaffold(
      appBar: AppBar(title: const Text('Unsupported Platform')),
      body: const Center(
        child: Text('Only Windows and Web builds are supported.'),
      ),
    );
  }
}
