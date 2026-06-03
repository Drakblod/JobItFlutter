import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isForeman => _currentUser?.role == 'Foreman';
  bool get isWorker => _currentUser?.role == 'Worker';

  AuthService() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('UserId');
      
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null && savedUid == currentFirebaseUser.uid) {
        await _fetchUserProfile(currentFirebaseUser.uid);
      } else if (currentFirebaseUser != null) {
        await _fetchUserProfile(currentFirebaseUser.uid);
      } else if (savedUid != null && savedUid.isNotEmpty) {
        // Fallback or attempt to restore session if firebase_auth is still initializing
        await _fetchUserProfile(savedUid);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    final ref = _db.ref('users/$uid');
    final snapshot = await ref.get();
    
    if (snapshot.exists && snapshot.value is Map) {
      _currentUser = AppUser.fromJson(snapshot.value as Map, uid);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('UserId', uid);
      await prefs.setString('UserRole', _currentUser!.role);
      
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        await prefs.setString('UserToken', token);
      }
    } else {
      _currentUser = null;
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _fetchUserProfile(credential.user!.uid);
        if (_currentUser != null) {
          return _currentUser!.role;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String displayName, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = AppUser(
        id: uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: role,
      );

      // Write user details to Database
      final ref = _db.ref('users/$uid');
      await ref.set(newUser.toJson());

      _currentUser = newUser;

      // Save preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('UserId', uid);
      await prefs.setString('UserRole', role);
      final token = await credential.user?.getIdToken();
      if (token != null) {
        await prefs.setString('UserToken', token);
      }

      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? displayName, String? phone, String? profilePicUrl}) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        phone: phone,
        profilePicUrl: profilePicUrl,
      );

      final ref = _db.ref('users/${_currentUser!.id}');
      await ref.update(updatedUser.toJson());
      
      _currentUser = updatedUser;
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('UserToken');
      await prefs.remove('UserId');
      await prefs.remove('UserRole');
      
      _currentUser = null;
    } catch (e) {
      debugPrint('Signout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
