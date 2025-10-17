// Posture analysis result returned by the Python backend's computer vision (CV) posture model. 
// The backend processes an image frame sent from the Flutter client.

enum PostureGrade { bad, okay, good, great }

class PostureResult {
  final String postureGrade; // categorical value
  final double postureScore; // continuous value from 0 to 100
  final double confidence; // continous value from 0 to 1

  PostureResult({
    required this.postureGrade,
    required this.postureScore,
    required this.confidence,
  });

  factory PostureResult.fromJson(Map<String, dynamic> json) {
    return PostureResult(
      postureGrade: json['posture_grade'],
      postureScore: (json['posture_score'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
