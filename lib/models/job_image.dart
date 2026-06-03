class JobImage {
  final String id;
  final String jobId;
  final String url;
  final String uploadedBy;
  final DateTime uploadedAt;

  JobImage({
    required this.id,
    required this.jobId,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory JobImage.fromJson(Map<dynamic, dynamic> json, String id) {
    String uploadedStr = json['UploadedAt'] ?? json['uploadedAt'] ?? '';
    DateTime uploaded = uploadedStr.isNotEmpty 
        ? DateTime.parse(uploadedStr) 
        : DateTime.now();

    return JobImage(
      id: id,
      jobId: json['JobId'] ?? json['jobId'] ?? '',
      url: json['Url'] ?? json['url'] ?? '',
      uploadedBy: json['UploadedBy'] ?? json['uploadedBy'] ?? '',
      uploadedAt: uploaded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'JobId': jobId,
      'Url': url,
      'UploadedBy': uploadedBy,
      'UploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
