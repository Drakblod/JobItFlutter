import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/subtask.dart';
import '../models/job_image.dart';
import '../models/timesheet_entry.dart';
import 'firebase_parser.dart';

class JobService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Streams for real-time dashboards
  Stream<List<Job>> streamActiveJobsForForeman(String foremanId) {
    return _db.ref('jobs').onValue.map((event) {
      final List<Job> jobs = [];
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = FirebaseParser.convertToMap(snapshot.value);
        data.forEach((key, val) {
          if (val is Map) {
            final job = Job.fromJson(val, key);
            if (job.createdBy == foremanId && !job.isCompleted) {
              jobs.add(job);
            }
          }
        });
      }
      return jobs;
    });
  }

  Stream<List<Job>> streamActiveJobsForWorker(String workerId) {
    return _db.ref('jobs').onValue.map((event) {
      final List<Job> jobs = [];
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = FirebaseParser.convertToMap(snapshot.value);
        data.forEach((key, val) {
          if (val is Map) {
            final job = Job.fromJson(val, key);
            if (job.assignedWorkers.containsKey(workerId) && !job.isCompleted) {
              jobs.add(job);
            }
          }
        });
      }
      return jobs;
    });
  }

  Stream<Job?> streamJob(String jobId) {
    return _db.ref('jobs/$jobId').onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        return Job.fromJson(snapshot.value as Map, jobId);
      }
      return null;
    });
  }

  // Futures for one-off operations
  Future<String> createJob(Job job) async {
    try {
      final ref = _db.ref('jobs').push();
      job.id = ref.key!;
      await ref.set(job.toJson());
      return job.id;
    } catch (e) {
      debugPrint('Create job error: $e');
      rethrow;
    }
  }

  Future<List<Job>> getJobsForForeman(String foremanId) async {
    final snapshot = await _db.ref('jobs').get();
    final List<Job> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final job = Job.fromJson(val, key);
          if (job.createdBy == foremanId && !job.isCompleted) {
            list.add(job);
          }
        }
      });
    }
    return list;
  }

  Future<List<Job>> getArchivedJobs(String foremanId) async {
    final snapshot = await _db.ref('jobs').get();
    final List<Job> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final job = Job.fromJson(val, key);
          if (job.createdBy == foremanId && job.isCompleted) {
            list.add(job);
          }
        }
      });
    }
    list.sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
    return list;
  }

  Future<List<Job>> getJobsForWorker(String workerId) async {
    final snapshot = await _db.ref('jobs').get();
    final List<Job> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final job = Job.fromJson(val, key);
          if (job.assignedWorkers.containsKey(workerId) && !job.isCompleted) {
            list.add(job);
          }
        }
      });
    }
    return list;
  }

  Future<List<Job>> getArchivedJobsForWorker(String workerId) async {
    final snapshot = await _db.ref('jobs').get();
    final List<Job> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final job = Job.fromJson(val, key);
          if (job.assignedWorkers.containsKey(workerId) && job.isCompleted) {
            list.add(job);
          }
        }
      });
    }
    list.sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
    return list;
  }


  Future<Job?> getJobByCode(String jobCode) async {
    final snapshot = await _db.ref('jobs').get();
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      for (var entry in data.entries) {
        if (entry.value is Map) {
          final job = Job.fromJson(entry.value as Map, entry.key);
          if (job.jobCode.toUpperCase() == jobCode.toUpperCase()) {
            return job;
          }
        }
      }
    }
    return null;
  }

  Future<bool> isJobCodeAvailable(String code, [String? excludeJobId]) async {
    if (code.isEmpty) return false;
    final snapshot = await _db.ref('jobs').get();
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      for (var entry in data.entries) {
        if (entry.value is Map) {
          final job = Job.fromJson(entry.value as Map, entry.key);
          if (job.jobCode.toUpperCase() == code.toUpperCase() && entry.key != excludeJobId) {
            return false;
          }
        }
      }
    }
    return true;
  }


  Future<void> updateJobCode(String jobId, String newCode) async {
    await _db.ref('jobs/$jobId').update({
      'JobCode': newCode,
    });
  }

  Future<void> assignJob(String jobId, String workerId, String workerName) async {
    await _db.ref('jobs/$jobId/AssignedWorkers/$workerId').set(workerName);
    await _db.ref('jobs/$jobId').update({
      'Status': 'Assigned',
    });
  }

  Future<void> completeJob(String jobId, String userId, String userName) async {
    await _db.ref('jobs/$jobId').update({
      'Status': 'Completed',
      'IsCompleted': true,
      'CompletedAt': DateTime.now().toUtc().toIso8601String(),
      'CompletedBy': userId,
      'CompletedByName': userName,
    });
  }

  Future<void> addJobImage(String jobId, JobImage image) async {
    await _db.ref('jobs/$jobId/images').push().set(image.toJson());
  }

  Future<void> addSubtask(String jobId, Subtask subtask) async {
    final ref = _db.ref('jobs/$jobId/subtasks').push();
    subtask.id = ref.key!;
    await ref.set(subtask.toJson());
  }

  Future<void> toggleSubtask(String jobId, String subtaskId, bool isCompleted) async {
    await _db.ref('jobs/$jobId/subtasks/$subtaskId').update({
      'IsCompleted': isCompleted,
    });
  }

  Future<void> logHours(TimesheetEntry entry) async {
    await _db.ref('timesheets').push().set(entry.toJson());
  }

  Future<List<TimesheetEntry>> getTimesheetsForWorker(String workerId) async {
    final snapshot = await _db.ref('timesheets').get();
    final List<TimesheetEntry> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final entry = TimesheetEntry.fromJson(val, key);
          if (entry.workerId == workerId) {
            list.add(entry);
          }
        }
      });
    }
    return list;
  }

  Future<int> getJobCount(String userId, String role) async {
    final snapshot = await _db.ref('jobs').get();
    int count = 0;
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          final job = Job.fromJson(val, key);
          if (role == 'Foreman') {
            if (job.createdBy == userId) count++;
          } else {
            if (job.assignedWorkers.containsKey(userId)) count++;
          }
        }
      });
    }
    return count;
  }


  Future<List<TimesheetEntry>> getAllTimesheets() async {
    final snapshot = await _db.ref('timesheets').get();
    final List<TimesheetEntry> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          list.add(TimesheetEntry.fromJson(val, key));
        }
      });
    }
    return list;
  }

  Future<Map<String, Job>> getJobsMap() async {
    final snapshot = await _db.ref('jobs').get();
    final Map<String, Job> map = {};
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          map[key] = Job.fromJson(val, key);
        }
      });
    }
    return map;
  }

  Future<void> deleteJob(String jobId) async {
    await _db.ref('jobs/$jobId').remove();
  }
}
