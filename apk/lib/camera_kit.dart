import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:camerakit_flutter/camerakit_flutter.dart';
import 'package:camerakit_flutter/lens_model.dart';

class Constants {
  static const List<String> groupIdList = [
    "a0c7f4f8-6ace-4d41-9a3a-f7e4dc2d65bd" // replace with your real groupId
  ];
}


class CameraKitHomePage extends StatefulWidget {
  const CameraKitHomePage({super.key});

  @override
  State<CameraKitHomePage> createState() => _CameraKitHomePageState();
}

class _CameraKitHomePageState extends State<CameraKitHomePage>
    implements CameraKitFlutterEvents {
  late final CameraKitFlutterImpl _cameraKitFlutterImpl;
  bool isLoading = false;
  bool isOpeningLens = false;
  late String _filePath = '';
  late String _fileType = '';

  @override
  void initState() {
    super.initState();
    _cameraKitFlutterImpl = CameraKitFlutterImpl(cameraKitFlutterEvents: this);
  }

  void openCameraWithLens(String lensId, String groupId) {
    setState(() => isOpeningLens = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraKitFlutterImpl.openCameraKitWithSingleLens(
        lensId: lensId,
        groupId: groupId,
        isHideCloseButton: false,
      );
    });
  }

  Future<void> showLensList() async {
    setState(() => isLoading = true);
    try {
      await _cameraKitFlutterImpl.getGroupLenses(groupIds: Constants.groupIdList);
    } on PlatformException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load lenses")),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  void onCameraKitResult(Map result) {
    setState(() {
      _filePath = result['path'];
      _fileType = result['type'];
    });

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MediaViewer(path: _filePath, type: _fileType),
    ));
  }

  @override
  void receivedLenses(List<Lens> lensList) async {
    setState(() => isLoading = false);

    if (lensList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No lenses found.")),
      );
      return;
    }

      final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LensSelector(lensList: lensList),
    )) as Map<String, dynamic>?;

    if (result != null) {
      openCameraWithLens(result['lensId']!, result['groupId']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Snap Camera Kit")),
      body: Center(
        child: isOpeningLens
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: showLensList,
                    child: const Text("Choose Lens"),
                  ),
                  const SizedBox(height: 20),
                  if (isLoading) const CircularProgressIndicator(),
                ],
              ),
      ),
    );
  }
}

class LensSelector extends StatelessWidget {
  final List<Lens> lensList;
  const LensSelector({super.key, required this.lensList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select a Lens")),
      body: ListView.builder(
        itemCount: lensList.length,
        itemBuilder: (context, index) {
          final lens = lensList[index];
          return ListTile(
            title: Text(lens.name ?? 'Unnamed Lens'),
            subtitle: Text(lens.id!),
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              await Future.delayed(const Duration(milliseconds: 300));
              Navigator.pop(context); // Close spinner
              Navigator.pop(context, {
                'lensId': lens.id,
                'groupId': lens.groupId,
              });
            },
          );
        },
      ),
    );
  }
}

class MediaViewer extends StatelessWidget {
  final String path;
  final String type;
  const MediaViewer({super.key, required this.path, required this.type});

  @override
  Widget build(BuildContext context) {
    final isVideo = type.toLowerCase().contains('video');
    return Scaffold(
      appBar: AppBar(title: const Text("Captured Media")),
      body: Center(
        child: isVideo
            ? Text("Video captured at: $path")
            : Image.file(
                File(path),
                fit: BoxFit.contain,
                cacheWidth: 1024,
              ),
      ),
    );
  }
}
