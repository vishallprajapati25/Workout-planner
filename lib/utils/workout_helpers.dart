class WorkoutHelpers {
  static Map<String, dynamic> getGoalConfiguration(String goal) {
    switch (goal) {
      case 'Muscle Gain':
        return {
          'sets': 4, // Higher volume for hypertrophy
          'reps': 8, // Lower reps, usually heavier weight
          'displayReps': "8-12",
          'rest': 90, // Longer rest to recover strength
          'intensity': "High",
          'color': 0xFF2196F3, // Blue
        };
      case 'Weight Loss':
        return {
          'sets': 3,
          'reps': 15, // High reps to keep heart rate up
          'displayReps': "15-20",
          'rest': 30, // Short rest for metabolic burn
          'intensity': "Very High",
          'color': 0xFFFF9800, // Orange
        };
      case 'Keep Fit':
        return {
          'sets': 3,
          'reps': 12, // Balanced maintenance volume
          'displayReps': "12",
          'rest': 60, // Standard recovery
          'intensity': "Moderate",
          'color': 0xFF4CAF50, // Green
        };
      default:
        return {
          'sets': 3,
          'reps': 10,
          'displayReps': "10",
          'rest': 60,
          'intensity': "Moderate",
          'color': 0xFF9E9E9E, // Grey
        };
    }
  }

  /// UPDATED: Removed automatic increase.
  /// Simply returns the current weight to maintain consistency.
  static double calculateNextSessionWeight(double lastWeight, String feedback) {
    return lastWeight; 
  }
}