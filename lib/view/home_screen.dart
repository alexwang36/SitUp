import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodel/camera_viewmodel.dart';
import 'view_sessions_screen.dart';

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
        body: Center(
          child: Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final controller = vm.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: Text('Camera not available')));
    }

    const double overlayFontSize = 20;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Camera')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: Stack(
                          children: [
                            CameraPreview(controller),
                            if (!vm.isSessionActive)
                              Container(color: Colors.black.withOpacity(0.6)),
                          ],
                        ),
                      ),

                      if (vm.isSessionActive)
                        Positioned(
                          bottom: 60,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              vm.postureStatus ?? 'Analyzing posture',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: overlayFontSize,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Score: ${vm.latestScore?.toStringAsFixed(1) ?? '--'}   '
              'Conf: ${(vm.latestConfidence != null ? (vm.latestConfidence! * 100).toStringAsFixed(0) : '--')}%',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Container(
            width: 200,
            margin: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton(
              onPressed: () {
                if (vm.isSessionActive) {
                  vm.stopSession();
                } else {
                  vm.startSession();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                backgroundColor: vm.isSessionActive ? Colors.red : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                vm.isSessionActive ? 'Stop Session' : 'Start Session',
                style: const TextStyle(fontSize: overlayFontSize, color: Colors.white),
              ),
            ),
          ),
          Container(
            width: 200,
            margin: const EdgeInsets.only(bottom: 40),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewSessionsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('View Past Sessions'),
            ),
          ),
        ],
      ),
    );
  }
}