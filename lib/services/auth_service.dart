import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. UPDATED: Unified Signup Logic
  // Now includes 'name' and initializes 'customWorkouts' for a complete profile
  Future<User?> signUpUser({
    required String name,      
    required String email,
    required String password,
    required String goal,
    required double weight,
    required double height,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        // Initialize the UserModel with ALL required fields
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,               
          goal: goal,
          weight: weight,
          height: height,
          age: 0,                   // Default value
          performanceHistory: {},   // Empty map for adaptive tracking
          workoutCount: 0,          // Leveling system starts at 0
          streakCount: 0,           // Streak module starts at 0
          lastWorkoutDate: '',      // Initialized for logic checks
          customWorkouts: [],       // NEW: Initialize empty list for custom routines
        );

        // Save the full model to Firestore
        await _db.collection('users').doc(result.user!.uid).set(newUser.toMap());
        debugPrint("User profile created for: $name");
      }
      return result.user;
    } catch (e) {
      debugPrint("Signup Error: $e");
      return null;
    }
  }

  // 2. Professional Login Logic
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      return null;
    }
  }

  // 3. Simple Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // 4. Auth State Stream (Used by main.dart Auth Gate)
  Stream<User?> get userStatus => _auth.authStateChanges();
}