import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
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

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    final controller = vm.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: Text('Camera not available')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Camera')),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 36,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vm.postureStatus ?? 'Analyzing posture',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
