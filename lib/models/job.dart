import 'route_point.dart';
import 'subtask.dart';
import 'job_image.dart';
import 'job_message.dart';

class Job {
  String id;
  final String title;
  final String description;
  final String address;
  String status; // "Open", "Assigned", "Completed", "Closed"
  final String createdBy; // Foreman ID
  final Map<String, String> assignedWorkers; // WorkerID -> DisplayName
  final String jobCode; // 6-character code
  final double latitude;
  final double longitude;
  final String jobType; // "Normal" or "Snowracer"
  final List<RoutePoint> routePoints;
  final String? userSpeech;
  final DateTime createdAt;
  bool isCompleted;
  DateTime? completedAt;
  String? completedBy;
  String? completedByName;
  final Map<String, JobImage> images;
  final Map<String, JobMessage> messages;
  final Map<String, Subtask> subtasks;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.createdBy,
    required this.assignedWorkers,
    required this.jobCode,
    required this.latitude,
    required this.longitude,
    this.jobType = 'Normal',
    required this.routePoints,
    this.userSpeech,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.completedByName,
    required this.images,
    required this.messages,
    required this.subtasks,
  });

  factory Job.fromJson(Map<dynamic, dynamic> json, String id) {
    // Assigned Workers
    Map<String, String> workers = {};
    if (json['AssignedWorkers'] != null && json['AssignedWorkers'] is Map) {
      (json['AssignedWorkers'] as Map).forEach((key, val) {
        workers[key.toString()] = val.toString();
      });
    }

    // Route points
    List<RoutePoint> pts = [];
    if (json['RoutePoints'] != null && json['RoutePoints'] is List) {
      for (var item in json['RoutePoints']) {
        if (item != null) {
          pts.add(RoutePoint.fromJson(item as Map));
        }
      }
    }

    // Created At
    String createdStr = json['CreatedAt'] ?? json['createdAt'] ?? '';
    DateTime created = createdStr.isNotEmpty 
        ? DateTime.parse(createdStr) 
        : DateTime.now();

    // Completed At
    String? compStr = json['CompletedAt'] ?? json['completedAt'];
    DateTime? completed = (compStr != null && compStr.isNotEmpty)
        ? DateTime.parse(compStr)
        : null;

    // Images
    Map<String, JobImage> imgs = {};
    if (json['images'] != null && json['images'] is Map) {
      (json['images'] as Map).forEach((k, v) {
        imgs[k.toString()] = JobImage.fromJson(v as Map, k.toString());
      });
    }

    // Messages
    Map<String, JobMessage> msgs = {};
    if (json['messages'] != null && json['messages'] is Map) {
      (json['messages'] as Map).forEach((k, v) {
        msgs[k.toString()] = JobMessage.fromJson(v as Map, k.toString());
      });
    }

    // Subtasks
    Map<String, Subtask> subs = {};
    if (json['subtasks'] != null && json['subtasks'] is Map) {
      (json['subtasks'] as Map).forEach((k, v) {
        subs[k.toString()] = Subtask.fromJson(v as Map, k.toString());
      });
    }

    return Job(
      id: id,
      title: json['Title'] ?? json['title'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      address: json['Address'] ?? json['address'] ?? '',
      status: json['Status'] ?? json['status'] ?? 'Open',
      createdBy: json['CreatedBy'] ?? json['createdBy'] ?? '',
      assignedWorkers: workers,
      jobCode: json['JobCode'] ?? json['jobCode'] ?? '',
      latitude: (json['Latitude'] ?? json['latitude'] ?? 0.0) as double,
      longitude: (json['Longitude'] ?? json['longitude'] ?? 0.0) as double,
      jobType: json['JobType'] ?? json['jobType'] ?? 'Normal',
      routePoints: pts,
      userSpeech: json['UserSpeech'] ?? json['userSpeech'],
      createdAt: created,
      isCompleted: json['IsCompleted'] ?? json['isCompleted'] ?? false,
      completedAt: completed,
      completedBy: json['CompletedBy'] ?? json['completedBy'],
      completedByName: json['CompletedByName'] ?? json['completedByName'],
      images: imgs,
      messages: msgs,
      subtasks: subs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Title': title,
      'Description': description,
      'Address': address,
      'Status': status,
      'CreatedBy': createdBy,
      'AssignedWorkers': assignedWorkers,
      'JobCode': jobCode,
      'Latitude': latitude,
      'Longitude': longitude,
      'JobType': jobType,
      'RoutePoints': routePoints.map((p) => p.toJson()).toList(),
      'UserSpeech': userSpeech,
      'CreatedAt': createdAt.toIso8601String(),
      'IsCompleted': isCompleted,
      'CompletedAt': completedAt?.toIso8601String(),
      'CompletedBy': completedBy,
      'CompletedByName': completedByName,
      'images': images.map((k, v) => MapEntry(k, v.toJson())),
      'messages': messages.map((k, v) => MapEntry(k, v.toJson())),
      'subtasks': subtasks.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  List<JobImage> get imageList => images.values.toList();
  List<Subtask> get subtaskList => subtasks.values.toList();
  List<JobMessage> get messageList => messages.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}
