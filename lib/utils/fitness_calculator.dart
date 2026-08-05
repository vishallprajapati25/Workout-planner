
class FitnessCalculator {
  // Calculate BMI: weight (kg) / [height (m)]^2
  static double calculateBMI(double weight, double heightCm) {
    double heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  // Estimate calories burnt based on goal and workout duration
  static int estimateCalories(String goal, int durationMinutes) {
    int burnRate;
    if (goal == "Weight Loss") {
      burnRate = 10; // High intensity burn
    } else if (goal == "Weight Gain") {
      burnRate = 6;  // Strength focus
    } else {
      burnRate = 8;  // Balanced
    }
    return durationMinutes * burnRate;
  }
}