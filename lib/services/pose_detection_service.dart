// This file should be placed in: YourFlutterApp/lib/services/pose_detection_service.dart

import 'dart:async';
import 'package:flutter/services.dart';

class PoseDetectionService {
  static const MethodChannel _methodChannel = MethodChannel('pose_detection');
  static const EventChannel _eventChannel = EventChannel(
    'pose_detection_stream',
  );

  Stream<Map<String, dynamic>>? _detectionStream;

  /// Initialize the pose detection service
  ///
  /// Parameters:
  /// - [modelPath]: Path to the model file (optional, defaults to lite model)
  /// - [numPoses]: Maximum number of poses to detect (default: 1)
  /// - [minDetectionConfidence]: Minimum confidence for detection (0.0-1.0)
  /// - [minPresenceConfidence]: Minimum confidence for presence (0.0-1.0)
  /// - [minTrackingConfidence]: Minimum confidence for tracking (0.0-1.0)
  /// - [useGPU]: Whether to use GPU acceleration (default: false)
  Future<bool> initialize({
    String? modelPath,
    int numPoses = 1,
    double minDetectionConfidence = 0.5,
    double minPresenceConfidence = 0.5,
    double minTrackingConfidence = 0.5,
    bool useGPU = false,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('initialize', {
        'modelPath': modelPath,
        'numPoses': numPoses,
        'minDetectionConfidence': minDetectionConfidence,
        'minPresenceConfidence': minPresenceConfidence,
        'minTrackingConfidence': minTrackingConfidence,
        'useGPU': useGPU,
      });
      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to initialize pose detection: ${e.message}');
      return false;
    }
  }

  /// Detect poses in an image
  ///
  /// [imagePath]: Local file path to the image
  /// Returns: Map containing detection results
  Future<Map<String, dynamic>?> detectImage(String imagePath) async {
    try {
      print('[PoseDetectionService] Calling detectImage with path: $imagePath');
      final result = await _methodChannel.invokeMethod('detectImage', {
        'imagePath': imagePath,
      });
      print('[PoseDetectionService] Detection successful, result: $result');

      // Convert Map<Object?, Object?> to Map<String, dynamic> recursively
      return _convertToMap(result);
    } on PlatformException catch (e) {
      print('Failed to detect poses in image');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      print('  Details: ${e.details}');
      return null;
    } catch (e, stackTrace) {
      print('Unexpected error during pose detection: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Recursively convert Map<Object?, Object?> to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), _convertToDynamic(val)),
      );
    }
    return {};
  }

  /// Convert dynamic value to appropriate type
  dynamic _convertToDynamic(dynamic value) {
    if (value is Map) {
      return _convertToMap(value);
    } else if (value is List) {
      return value.map((item) => _convertToDynamic(item)).toList();
    }
    return value;
  }

  /// Start continuous pose detection (not yet implemented for camera)
  ///
  /// Currently not implemented. Use detectImage for individual image processing.
  Future<bool> startCameraStream() async {
    try {
      final result = await _methodChannel.invokeMethod('startCameraStream');
      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to start camera stream: ${e.message}');
      return false;
    }
  }

  /// Stop the camera stream
  Future<bool> stopCameraStream() async {
    try {
      final result = await _methodChannel.invokeMethod('stopCameraStream');
      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to stop camera stream: ${e.message}');
      return false;
    }
  }

  /// Dispose of the pose detection service
  Future<bool> dispose() async {
    try {
      final result = await _methodChannel.invokeMethod('dispose');
      return result as bool;
    } on PlatformException {
      return false;
    }
  }

  /// Get a stream of detection results
  ///
  /// Returns: Stream of pose detection results
  Stream<Map<String, dynamic>> get detectionStream {
    _detectionStream ??= _eventChannel.receiveBroadcastStream().map(
      (dynamic event) => event as Map<String, dynamic>,
    );
    return _detectionStream!;
  }
}
