class Subtask {
  String id;
  final String jobId;
  final String title;
  final String description;
  bool isCompleted;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String> photoUrls;
  final DateTime createdAt;

  Subtask({
    required this.id,
    required this.jobId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.photoUrls,
    required this.createdAt,
  });

  factory Subtask.fromJson(Map<dynamic, dynamic> json, String id) {
    var photosList = json['PhotoUrls'] ?? json['photoUrls'] ?? [];
    List<String> photos = List<String>.from(photosList);
    
    String createdStr = json['CreatedAt'] ?? json['createdAt'] ?? '';
    DateTime created = createdStr.isNotEmpty 
        ? DateTime.parse(createdStr) 
        : DateTime.now();

    return Subtask(
      id: id,
      jobId: json['JobId'] ?? json['jobId'] ?? '',
      title: json['Title'] ?? json['title'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      isCompleted: json['IsCompleted'] ?? json['isCompleted'] ?? false,
      latitude: (json['Latitude'] ?? json['latitude'] ?? 0.0) as double,
      longitude: (json['Longitude'] ?? json['longitude'] ?? 0.0) as double,
      address: json['Address'] ?? json['address'],
      photoUrls: photos,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'JobId': jobId,
      'Title': title,
      'Description': description,
      'IsCompleted': isCompleted,
      'Latitude': latitude,
      'Longitude': longitude,
      'Address': address,
      'PhotoUrls': photoUrls,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
