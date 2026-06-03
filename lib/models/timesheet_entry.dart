class TimesheetEntry {
  final String id;
  final String jobId;
  final String workerId;
  final String workerName;
  final double hoursWorked;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  TimesheetEntry({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    required this.hoursWorked,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory TimesheetEntry.fromJson(Map<dynamic, dynamic> json, String id) {
    String dateStr = json['Date'] ?? json['date'] ?? '';
    DateTime dt = dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();

    String createdStr = json['CreatedAt'] ?? json['createdAt'] ?? '';
    DateTime cr = createdStr.isNotEmpty ? DateTime.parse(createdStr) : DateTime.now();

    return TimesheetEntry(
      id: id,
      jobId: json['JobId'] ?? json['jobId'] ?? '',
      workerId: json['WorkerId'] ?? json['workerId'] ?? '',
      workerName: json['WorkerName'] ?? json['workerName'] ?? '',
      hoursWorked: (json['HoursWorked'] ?? json['hoursWorked'] ?? 0.0) as double,
      date: dt,
      notes: json['Notes'] ?? json['notes'],
      createdAt: cr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'JobId': jobId,
      'WorkerId': workerId,
      'WorkerName': workerName,
      'HoursWorked': hoursWorked,
      'Date': date.toIso8601String(),
      'Notes': notes,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
