class UserModel {
  final String uid;
  final String email;
  final String name; 
  final String goal;
  final double weight;
  final double height;
  final int age;
  
  // NEW: Field for storing the user's weight goal
  final double? targetWeight; 

  final Map<String, dynamic> performanceHistory;
  
  // Fields for tracking progress and adaptive difficulty
  final int workoutCount; 
  final int streakCount; 
  final String lastWorkoutDate;

  // Field for storing user-created custom routines
  final List<Map<String, dynamic>> customWorkouts; 

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    this.targetWeight, //
    required this.performanceHistory,
    required this.workoutCount,
    required this.streakCount,
    required this.lastWorkoutDate,
    required this.customWorkouts,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'goal': goal,
      'weight': weight,
      'height': height,
      'age': age,
      'targetWeight': targetWeight, //
      'performanceHistory': performanceHistory,
      'workoutCount': workoutCount,
      'streakCount': streakCount,
      'lastWorkoutDate': lastWorkoutDate,
      'customWorkouts': customWorkouts,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? 'User', 
      goal: data['goal'] ?? 'Keep Fit',
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      age: data['age'] ?? 0,
      // Safely parse targetWeight from Firestore
      targetWeight: data['targetWeight'] != null 
          ? (data['targetWeight'] as num).toDouble() 
          : null,
      performanceHistory: data['performanceHistory'] ?? {},
      workoutCount: data['workoutCount'] ?? 0,
      streakCount: data['streakCount'] ?? 0, 
      lastWorkoutDate: data['lastWorkoutDate'] ?? '',
      customWorkouts: List<Map<String, dynamic>>.from(data['customWorkouts'] ?? []), 
    );
  }
}