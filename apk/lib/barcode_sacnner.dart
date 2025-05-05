import 'package:camerakit_flutter/lens_model.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:camerakit_flutter/camerakit_flutter.dart';

class BarcodeSacnner extends StatefulWidget {
  const BarcodeSacnner({super.key});

  @override
  State<BarcodeSacnner> createState() => _BarcodeSacnnerState();
}

class _BarcodeSacnnerState extends State<BarcodeSacnner>  implements CameraKitFlutterEvents{
  final MobileScannerController _scannerController = MobileScannerController();
  late final CameraKitFlutterImpl _cameraKitFlutterImpl;

  Barcode? _barcode;
  String barcodeValue = "";
  String? lensId;
  String? groupId;
  bool scanned = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _cameraKitFlutterImpl = CameraKitFlutterImpl(cameraKitFlutterEvents: this);
  }

  Future<void> fetchLensIdAndOpen(String barcode) async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('https://wearmirror.com/api/lens/$barcode'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        lensId = data['lens_id'];
        groupId = data['group_id'];

        if (lensId != null && groupId != null) {
          await _cameraKitFlutterImpl.openCameraKitWithSingleLens(
            lensId: lensId!,
            groupId: groupId!,
            isHideCloseButton: false,
          );
        } else {
          showError("Invalid lens or group ID");
        }
      } else {
        showError("Failed to fetch lens. Status: ${response.statusCode}");
      }
    } catch (e) {
      showError("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.displayValue ?? 'No display value.',
          overflow: TextOverflow.fade,
          style: const TextStyle(color: Colors.white),
        ),
        if (lensId != null)
          Text(
            'Lens ID: $lensId',
            style: const TextStyle(color: Colors.greenAccent),
          ),
        if (groupId != null)
          Text(
            'Group ID: $groupId',
            style: const TextStyle(color: Colors.greenAccent),
          ),
      ],
    );
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (scanned) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    final String? rawValue = barcodes.first.rawValue;

    if (rawValue == null) {
      debugPrint('❌ Failed to scan Barcode');
      return;
    }

    setState(() {
      _barcode = barcodes.first;
      barcodeValue = rawValue;
      scanned = true;
    });

    debugPrint('✅ Barcode found: $rawValue');

    // Stop scanner and fetch lens
    _scannerController.stop();
    fetchLensIdAndOpen(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snap Lens Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : _barcodePreview(_barcode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void onCameraKitResult(Map result) {
    // TODO: implement onCameraKitResult
  }

  @override
  void receivedLenses(List<Lens> lensList) {
    // TODO: implement receivedLenses
  }
}
