import 'route_point.dart';
import 'subtask.dart';
import 'job_image.dart';
import 'job_message.dart';
import '../services/firebase_parser.dart';

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
    if (json['AssignedWorkers'] != null) {
      final workersMap = FirebaseParser.convertToMap(json['AssignedWorkers']);
      workersMap.forEach((key, val) {
        workers[key] = val.toString();
      });
    }

    // Route points
    List<RoutePoint> pts = [];
    if (json['RoutePoints'] != null) {
      final ptsMap = FirebaseParser.convertToMap(json['RoutePoints']);
      final sortedKeys = ptsMap.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      for (var key in sortedKeys) {
        final val = ptsMap[key];
        if (val is Map) {
          pts.add(RoutePoint.fromJson(val));
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
    if (json['images'] != null) {
      final imgsMap = FirebaseParser.convertToMap(json['images']);
      imgsMap.forEach((k, v) {
        if (v is Map) {
          imgs[k] = JobImage.fromJson(v, k);
        }
      });
    }

    // Messages
    Map<String, JobMessage> msgs = {};
    if (json['messages'] != null) {
      final msgsMap = FirebaseParser.convertToMap(json['messages']);
      msgsMap.forEach((k, v) {
        if (v is Map) {
          msgs[k] = JobMessage.fromJson(v, k);
        }
      });
    }

    // Subtasks
    Map<String, Subtask> subs = {};
    if (json['subtasks'] != null) {
      final subsMap = FirebaseParser.convertToMap(json['subtasks']);
      subsMap.forEach((k, v) {
        if (v is Map) {
          subs[k] = Subtask.fromJson(v, k);
        }
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
      latitude: ((json['Latitude'] ?? json['latitude'] ?? 0.0) as num).toDouble(),
      longitude: ((json['Longitude'] ?? json['longitude'] ?? 0.0) as num).toDouble(),

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
