import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraViewModel extends ChangeNotifier {
  final CameraService _cameraService;

  CameraController? _cameraController;
  bool _isLoading = false;
  String? _errorMessage;

  CameraViewModel(this._cameraService);

  CameraController? get cameraController => _cameraController;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initCamera() async {
    _setLoading(true);
    try {
      await _cameraService.initialize();
      _cameraController = _cameraService.controller;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Camera init error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> disposeCamera() async {
    await _cameraService.dispose();
    _cameraController = null;
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
