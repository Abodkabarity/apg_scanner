import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (isScanned) return;
    isScanned = true;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value == null) return;

    controller.stop().then((_) {
      if (!mounted) return;
      Navigator.pop(context, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MobileScanner(controller: controller, onDetect: _onBarcodeDetect),
    );
  }
}
