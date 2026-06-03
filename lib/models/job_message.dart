class JobMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  JobMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory JobMessage.fromJson(Map<dynamic, dynamic> json, String id) {
    String stampStr = json['Timestamp'] ?? json['timestamp'] ?? '';
    DateTime stamp = stampStr.isNotEmpty 
        ? DateTime.parse(stampStr) 
        : DateTime.now();

    return JobMessage(
      id: id,
      jobId: json['JobId'] ?? json['jobId'] ?? '',
      senderId: json['SenderId'] ?? json['senderId'] ?? '',
      senderName: json['SenderName'] ?? json['senderName'] ?? '',
      text: json['Text'] ?? json['text'] ?? '',
      timestamp: stamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'JobId': jobId,
      'SenderId': senderId,
      'SenderName': senderName,
      'Text': text,
      'Timestamp': timestamp.toIso8601String(),
    };
  }
}
