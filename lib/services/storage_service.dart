import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(Uint8List bytes, String fullPath) async {
    try {
      final ref = _storage.ref().child(fullPath);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    return uploadFile(bytes, 'job_images/$fileName');
  }

  Future<String> uploadProfilePicture(Uint8List bytes, String userId) async {
    return uploadFile(bytes, 'profile_pics/$userId.jpg');
  }
}
