import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. USER DATA & PROFILE ---

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

  Stream<UserModel?> streamUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // UPDATED: Added targetWeight to the profile update logic
  Future<void> updateProfile(
    String uid, {
    required String name,
    required double weight,
    required double height,
    required String goal,
    double? targetWeight, // New optional parameter
    double dailyCalorieTarget = 500.0,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'weight': weight,
        'height': height,
        'goal': goal,
        'dailyCalorieTarget': dailyCalorieTarget,
      };

      // Only add targetWeight to Firestore if it's provided
      if (targetWeight != null) {
        updateData['targetWeight'] = targetWeight;
      }

      await _db.collection('users').doc(uid).update(updateData);

      // Log to biometric history for the journey chart
      await _db.collection('users').doc(uid).collection('biometric_history').add({
        'weight': weight,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getWeightHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('biometric_history')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // --- 2. CUSTOM WORKOUTS ---

  Future<void> createCustomWorkout(String uid, String title, List<ExerciseModel> exercises) async {
    try {
      List<Map<String, dynamic>> exerciseData = exercises.map((e) => {
        'id': e.id,
        'name': e.name,
        'bodyPart': e.bodyPart,
        'difficulty': e.difficulty,
        'targetedPart': e.targetedPart, // Added to ensure data consistency
      }).toList();

      await _db.collection('users').doc(uid).update({
        'customWorkouts': FieldValue.arrayUnion([
          {
            'title': title,
            'exercises': exerciseData,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ])
      });
    } catch (e) {
      debugPrint("Error saving custom workout: $e");
      rethrow;
    }
  }

  Future<void> updateCustomWorkoutExercises(String uid, String routineTitle, List<ExerciseModel> newExercises) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        List<dynamic> workouts = List.from(userDoc.get('customWorkouts') ?? []);
        int index = workouts.indexWhere((w) => w['title'] == routineTitle);

        if (index != -1) {
          List<Map<String, dynamic>> exerciseData = newExercises.map((e) => {
            'id': e.id,
            'name': e.name,
            'bodyPart': e.bodyPart,
            'difficulty': e.difficulty,
            'targetedPart': e.targetedPart,
          }).toList();

          workouts[index]['exercises'] = exerciseData;
          await userRef.update({'customWorkouts': workouts});
        }
      }
    } catch (e) {
      debugPrint("Error updating routine: $e");
      rethrow;
    }
  }

  Future<void> deleteCustomWorkout(String uid, Map<String, dynamic> workoutData) async {
    try {
      await _db.collection('users').doc(uid).update({
        'customWorkouts': FieldValue.arrayRemove([workoutData])
      });
    } catch (e) {
      debugPrint("Error deleting workout: $e");
      rethrow;
    }
  }

  // --- 3. DAILY WORKOUT PERSISTENCE ---

  Future<void> saveDailyWorkout(String uid, List<ExerciseModel> exercises) async {
    try {
      List<Map<String, dynamic>> exerciseData = exercises.map((e) => {
        'id': e.id,
        'name': e.name,
        'bodyPart': e.bodyPart,
        'difficulty': e.difficulty,
        'targetedPart': e.targetedPart,
      }).toList();

      await _db.collection('users').doc(uid).update({
        'dailyWorkout': {
          'exercises': exerciseData,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }
      });
    } catch (e) {
      debugPrint("Error saving daily workout: $e");
    }
  }

  Future<List<ExerciseModel>?> getPersistedDailyWorkout(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('dailyWorkout')) {
          String savedDate = data['dailyWorkout']['date'];
          String today = DateTime.now().toIso8601String().split('T')[0];
          if (savedDate == today) {
            List dynamicList = data['dailyWorkout']['exercises'] ?? [];
            return dynamicList.map((e) => ExerciseModel.fromMap(Map<String, dynamic>.from(e))).toList();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 4. EXERCISE RETRIEVAL ---

  Future<List<ExerciseModel>> getExercises() async {
    try {
      QuerySnapshot snapshot = await _db.collection('exercises').get();
      return snapshot.docs.map((doc) => ExerciseModel.fromMap(doc.data() as Map<String, dynamic>, customId: doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- 5. LOGGING & STATS ---

  Future<void> logExerciseSession({
    required String uid,
    required String exerciseName,
    required List<double> setWeights,
    required int reps,
    required double userBodyWeight,
  }) async {
    try {
      // Logic for calorie calculation based on volume
      double avgWeight = setWeights.reduce((a, b) => a + b) / setWeights.length;
      await _db.collection('users').doc(uid).collection('workout_history').add({
        'exerciseName': exerciseName,
        'setWeights': setWeights,
        'averageWeight': double.parse(avgWeight.toStringAsFixed(1)),
        'reps': reps,
        'sets': setWeights.length,
        'timestamp': FieldValue.serverTimestamp(),
        'caloriesBurned': (reps * setWeights.length * 0.15).toInt(),
      });

      // Automatically update user performance history with the latest weights used
      await _db.collection('users').doc(uid).update({
        'performanceHistory.$exerciseName': avgWeight,
      });
    } catch (e) {
      debugPrint("Failed to log history: $e");
    }
  }

  Future<void> updateUserWorkoutStats({required String uid, bool incrementWorkoutCount = false}) async {
    Map<String, dynamic> updates = {'lastWorkoutDate': DateTime.now().toIso8601String()};
    if (incrementWorkoutCount) updates['workoutCount'] = FieldValue.increment(1);
    await _db.collection('users').doc(uid).update(updates);
  }

  Stream<QuerySnapshot> getWorkoutHistoryStream(String uid) {
    return _db.collection('users').doc(uid).collection('workout_history').orderBy('timestamp', descending: true).snapshots();
  }
  // --- 5. LEAN SEEDING POOL (All 42 Exercises) ---

  final List<Map<String, dynamic>> _manualExercisePool = [
    // --- CHEST ---
    {"id": "0289", "name": "Dumbbell Bench Press", "bodyPart": "chest", "difficulty": "Intermediate"},
    {"id": "0025", "name": "Cable Chest Fly", "bodyPart": "chest", "difficulty": "Intermediate"},
    {"id": "0235", "name": "Dips", "bodyPart": "chest", "difficulty": "Advanced"},
    {"id": "0314", "name": "Incline Dumbbell Press", "bodyPart": "chest", "difficulty": "Intermediate"},
    {"id": "0662", "name": "Pushups", "bodyPart": "chest", "difficulty": "Beginner"},
    {"id": "0027", "name": "Cable Decline Fly", "bodyPart": "chest", "difficulty": "Advanced"},
    // --- BACK ---
    {"id": "0293", "name": "Dumbbell Row", "bodyPart": "back", "difficulty": "Intermediate"},
    {"id": "0180", "name": "Seated Cable Row", "bodyPart": "back", "difficulty": "Beginner"},
    {"id": "0150", "name": "Lat Pulldown", "bodyPart": "back", "difficulty": "Intermediate"},
    {"id": "0383", "name": "Dumbbell Shrugs", "bodyPart": "back", "difficulty": "Beginner"},
    {"id": "0196", "name": "Straight Arm Pulldown", "bodyPart": "back", "difficulty": "Advanced"},
    {"id": "0004", "name": "Barbell Deadlift", "bodyPart": "back", "difficulty": "Advanced"},
    // --- BICEPS ---
    {"id": "0285", "name": "Dumbbell Bicep Curl", "bodyPart": "biceps", "difficulty": "Beginner"},
    {"id": "0210", "name": "Cable Bicep Curl", "bodyPart": "biceps", "difficulty": "Beginner"},
    {"id": "0313", "name": "Hammer Curls", "bodyPart": "biceps", "difficulty": "Intermediate"},
    {"id": "0297", "name": "Incline Bicep Curl", "bodyPart": "biceps", "difficulty": "Intermediate"},
    {"id": "0682", "name": "Preacher Curl", "bodyPart": "biceps", "difficulty": "Advanced"},
    {"id": "0208", "name": "Concentration Curl", "bodyPart": "biceps", "difficulty": "Advanced"},
    // --- TRICEPS ---
    {"id": "0232", "name": "Tricep Pushdown", "bodyPart": "triceps", "difficulty": "Beginner"},
    {"id": "0333", "name": "Kickbacks", "bodyPart": "triceps", "difficulty": "Beginner"},
    {"id": "0168", "name": "Overhead Extension", "bodyPart": "triceps", "difficulty": "Intermediate"},
    {"id": "0215", "name": "Rope Pushdown", "bodyPart": "triceps", "difficulty": "Intermediate"},
    {"id": "1611", "name": "Skull Crushers", "bodyPart": "triceps", "difficulty": "Advanced"},
    {"id": "0021", "name": "Close Grip Press", "bodyPart": "triceps", "difficulty": "Advanced"},
    // --- SHOULDERS ---
    {"id": "0334", "name": "Lateral Raise", "bodyPart": "shoulders", "difficulty": "Beginner"},
    {"id": "0310", "name": "Front Raise", "bodyPart": "shoulders", "difficulty": "Beginner"},
    {"id": "0368", "name": "Shoulder Press", "bodyPart": "shoulders", "difficulty": "Intermediate"},
    {"id": "0203", "name": "Cable Lateral Raise", "bodyPart": "shoulders", "difficulty": "Intermediate"},
    {"id": "0174", "name": "Face Pulls", "bodyPart": "shoulders", "difficulty": "Advanced"},
    {"id": "0011", "name": "Military Press", "bodyPart": "shoulders", "difficulty": "Advanced"},
    // --- LEGS ---
    {"id": "0407", "name": "Goblet Squat", "bodyPart": "legs", "difficulty": "Beginner"},
    {"id": "1372", "name": "Calf Raise", "bodyPart": "legs", "difficulty": "Beginner"},
    {"id": "0339", "name": "Lunges", "bodyPart": "legs", "difficulty": "Intermediate"},
    {"id": "0353", "name": "Romanian Deadlift", "bodyPart": "legs", "difficulty": "Intermediate"},
    {"id": "0194", "name": "Cable Pull-Through", "bodyPart": "legs", "difficulty": "Advanced"},
    {"id": "0010", "name": "Barbell Squat", "bodyPart": "legs", "difficulty": "Advanced"},
    // --- ABS ---
    {"id": "0001", "name": "Ab Crunch", "bodyPart": "abs", "difficulty": "Beginner"},
    {"id": "0582", "name": "Leg Raises", "bodyPart": "abs", "difficulty": "Beginner"},
    {"id": "0018", "name": "Cable Crunch", "bodyPart": "abs", "difficulty": "Intermediate"},
    {"id": "0411", "name": "Side Bend", "bodyPart": "abs", "difficulty": "Intermediate"},
    {"id": "0175", "name": "Hanging Leg Raise", "bodyPart": "abs", "difficulty": "Advanced"},
    {"id": "0198", "name": "Woodchopper", "bodyPart": "abs", "difficulty": "Advanced"},
    // --- CARDIO ---
    {"id": "3221", "name": "Jumping Jacks", "bodyPart": "cardio", "difficulty": "Beginner"},
    {"id": "3671", "name": "High Knees", "bodyPart": "cardio", "difficulty": "Beginner"},
    {"id": "3016", "name": "Mountain Climbers", "bodyPart": "cardio", "difficulty": "Intermediate"},
    {"id": "3361", "name": "Jump Rope", "bodyPart": "cardio", "difficulty": "Intermediate"},
    {"id": "3637", "name": "Burpees", "bodyPart": "cardio", "difficulty": "Advanced"},
    {"id": "3224", "name": "Mountain Climber (Fast)", "bodyPart": "cardio", "difficulty": "Advanced"}
  ];

Future<void> seedDatabase() async {
    WriteBatch batch = _db.batch();
    CollectionReference exercises = _db.collection('exercises');
    for (var exercise in _manualExercisePool) {
      DocumentReference docRef = exercises.doc(exercise['name']);
      batch.set(docRef, exercise, SetOptions(merge: true));
    }
    await batch.commit();
  }
}