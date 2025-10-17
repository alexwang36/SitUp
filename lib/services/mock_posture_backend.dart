import 'dart:math';
import '../data/models/posture_result.dart';
import 'package:situp/services/posture_api_service.dart';

// We currently do not have a backend. This serves as a mock for testing the camera capture and return posture result data.
class MockPostureBackend implements PostureApiService {
  final _random = Random();

   @override
  Future<PostureResult> sendImageFile(String filePath) async {
    final randomScore = _random.nextDouble() * 100;
    final randomConfidence = _random.nextDouble();

    print('Mock backend successfully returned posture result');
    return PostureResult(
      postureScore: randomScore,
      confidence: randomConfidence,
    );
  }
}

