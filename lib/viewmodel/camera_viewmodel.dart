import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:situp/services/posture_api_service.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';


class CameraViewModel extends ChangeNotifier {
  static const Duration captureInterval = Duration(seconds: 6);

  final CameraService _cameraService;
  final PostureApiService _postureApiService;
  final DatabaseService _databaseService;

  CameraController? _cameraController;
  bool _isSessionActive = false;
  String? _sessionId;
  bool _isLoading = false;
  String? _errorMessage;
  String? _postureStatus;
  Timer? _timer;
  double? latestScore;
  double? latestConfidence;

  CameraViewModel(this._cameraService, this._postureApiService, this._databaseService);

  CameraController? get cameraController => _cameraController;
  bool get isSessionActive => _isSessionActive;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get postureStatus => _postureStatus;

  Future<void> initCamera() async {
    _setLoading(true);
    try {
      await _cameraService.initialize();
      _cameraController = _cameraService.controller;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startSession() async {
    try {
      _sessionId = await _databaseService.startNewSession();
      _isSessionActive = true;
      
      _timer?.cancel();
      _timer = Timer.periodic(captureInterval, (_) => _captureAndSend());
      
      notifyListeners();
      print('Session started and started capturing data for the session');
    } catch (e) {
      _errorMessage = '$e';
      print('Error starting session: $e');
      notifyListeners();
    }
  }

  Future<void> stopSession() async {
    _isSessionActive = false;
    _sessionId = null;
    _timer?.cancel();
    _postureStatus = null;
    latestScore = null;
    latestConfidence = null;
    notifyListeners();
    print('Session stopped');
  }

  Future<void> captureNowAndSend() async {
    return _captureAndSend();
  }

  Future<void> _captureAndSend() async {
    if (!_isSessionActive || _sessionId == null) {
      return;
    }

    try {
      final file = await _cameraService.takePicture();

      if (file == null) {
        print('takePicture() returned null');
        return;
      }

      final result = await _postureApiService.sendImageFile(file.path);
      _postureStatus = result.grade.name; 
      latestScore = result.postureScore;
      latestConfidence = result.confidence; 
      await _databaseService.addPostureDataPoint(_sessionId!, result);

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