class PostureSessionData {
  final String sessionId;
  final DateTime startTime;
  final List<PostureSessionDataPoint> dataPoints;
  
  PostureSessionData({
    required this.sessionId,
    required this.startTime,
    required this.dataPoints,
  });

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> dataPointsList = [];

    for (PostureSessionDataPoint point in dataPoints) {
      dataPointsList.add(point.toJson());
    }

    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'dataPoints': dataPointsList,
    };
  }

  static PostureSessionData fromJson(Map<String, dynamic> json) {
    String sessionId = json['sessionId'];
    DateTime startTime = DateTime.parse(json['startTime']);
    List<Map<String, dynamic>> dataPointsJson = json['dataPoints'];

    List<PostureSessionDataPoint> points = [];
    for (Map<String, dynamic> pointJson in dataPointsJson) {
      points.add(PostureSessionDataPoint.fromJson(pointJson));
    }

    return PostureSessionData(
      sessionId: sessionId,
      startTime: startTime,
      dataPoints: points,
    );
  }
}

class PostureSessionDataPoint {
  final DateTime timestamp;
  final double postureScore;
  final double confidence;

  
  PostureSessionDataPoint({
    required this.timestamp,
    required this.postureScore,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'postureScore': postureScore,
    'confidence': confidence,
  };

  static PostureSessionDataPoint fromJson(Map<String, dynamic> json) {
    DateTime timestamp = DateTime.parse(json['timestamp']);
    double postureScore = json['postureScore'] as double;
    double confidence = json['confidence'] as double;

    return PostureSessionDataPoint(
      timestamp: timestamp,
      postureScore: postureScore,
      confidence: confidence,
    );
  }
}