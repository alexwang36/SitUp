// Posture analysis result returned by the Python backend's computer vision (CV) posture model. 
// The backend processes an image frame sent from the Flutter client.

enum PostureGrade { bad, okay, good, great, unknown }

class PostureResult {
  final double postureScore; // continuous value from 0 to 100
  final double confidence; // continous value from 0 to 1

  PostureResult({
    required this.postureScore,
    required this.confidence,
  });

  factory PostureResult.fromJson(Map<String, dynamic> json) {
    return PostureResult(
      postureScore: (json['posture_score'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  PostureGrade get grade {
    if (postureScore < 0 || postureScore > 100) {
      return PostureGrade.unknown;
    } else if (postureScore >= 80) {
      return PostureGrade.great;
    } else if (postureScore >= 60) {
      return PostureGrade.good; 
    } else if (postureScore >= 35) {
      return PostureGrade.okay;
    } else {
      return PostureGrade.bad;
    }
  }
}
