import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:situp/services/posture_api_service.dart';
import '../services/camera_service.dart';

class CameraViewModel extends ChangeNotifier {
  static const Duration captureInterval = Duration(seconds: 30);

  final CameraService _cameraService;
  final PostureApiService _postureApiService;

  CameraController? _cameraController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _postureStatus;
  Timer? _timer;

  CameraViewModel(this._cameraService, this._postureApiService);

  CameraController? get cameraController => _cameraController;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get postureStatus => _postureStatus;

  Future<void> initCamera() async {
    _setLoading(true);
    try {
      await _cameraService.initialize();
      _cameraController = _cameraService.controller;
      _errorMessage = null;

      _timer?.cancel();
      _timer = Timer.periodic(captureInterval, (_) => _captureAndSend());
    } catch (e) {
      _errorMessage = 'error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> captureNowAndSend() async => _captureAndSend();

  Future<void> _captureAndSend() async {
    try {
      final file = await _cameraService.takePicture();

      if (file == null) {
        print('takePicture() returned null');
        return;
      }
    
      final result = await _postureApiService.sendImageFile(file.path);
    _postureStatus = result.grade.name; 
      print('successsfully sent image file to backend');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'e';
      print('error: $e');
      notifyListeners();
    }
  }

  Future<void> disposeCamera() async {
    _timer?.cancel();
    await _cameraService.dispose();
    _cameraController = null;
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

