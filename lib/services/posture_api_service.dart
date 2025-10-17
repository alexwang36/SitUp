import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../data/models/posture_result.dart';

// Handles sending image data to the Python backend and receiving
// the posture analysis result.

// TODO: set once implement backend
final String baseUrl = '';

class PostureApiService {
  final String _base = baseUrl;

  // Sends an image file to the backend's endpoint.
  // TODO: change endpoint name if it does not end up being named "/analyze_posture"

  Future<PostureResult> sendImageFile(String filePath) async {
    final uri = Uri.parse('$_base/analyze_posture');
    final request = http.MultipartRequest('POST', uri);

    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: path.basename(filePath),
    );
    request.files.add(file);

    final streamedResp = await request.send();
    final respString = await streamedResp.stream.bytesToString();
    if (streamedResp.statusCode >= 200 && streamedResp.statusCode < 300) {
      final data = json.decode(respString) as Map<String, dynamic>;

      return PostureResult(
        postureScore: (data['posture_score']).toDouble(),
        confidence: (data['confidence']).toDouble(),
      );
    } else {
      throw HttpException(
        'Server error ${streamedResp.statusCode}: $respString',
      );
    }
  }
}
