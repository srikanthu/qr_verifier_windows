import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/scanner_web.dart';
import 'screens/scanner_windows.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        child: Text(
          'This build is only supported on Web (for testing) and Windows.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
