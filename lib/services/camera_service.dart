import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera available');
    }

    final selectedCamera = kIsWeb
        ? cameras.first
        : cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

    final preset = ResolutionPreset.veryHigh;

    _controller = CameraController(
      selectedCamera,
      preset,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  // Take a picture on a set interval to send to the CV model
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      return await _controller!.takePicture();
    } catch (e) {
      rethrow;
    }
  }

  CameraController? get controller => _controller;

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}




