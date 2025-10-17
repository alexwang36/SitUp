import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart'; // needed for CameraPreview
import '../viewmodel/camera_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CameraViewModel _cameraVM;

  @override
  void initState() {
    super.initState();
    _cameraVM = context.read<CameraViewModel>();
    _cameraVM.initCamera();
  }

  @override
  void dispose() {
    _cameraVM.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CameraViewModel>();

    Widget body;
    if (vm.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vm.errorMessage != null) {
      body = Center(child: Text(vm.errorMessage!));
    } else if (vm.cameraController != null && vm.cameraController!.value.isInitialized) {
      body = Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: vm.cameraController!.value.aspectRatio,
              child: CameraPreview(vm.cameraController!),
            ),
          ),
        ),
      );
    } else {
      body = const Center(child: Text("Camera not available"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      backgroundColor: Colors.grey[200],
      body: body,
    );
  }
}