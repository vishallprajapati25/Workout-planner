import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart'; // Ensure correct relative path to your unified HomeScreen

class BodyStatsScreen extends StatefulWidget {
  final String name;         // Received from GoalSelectionScreen
  final String email;
  final String password;
  final String selectedGoal;

  const BodyStatsScreen({
    super.key, 
    required this.name,      
    required this.email, 
    required this.password, 
    required this.selectedGoal
  });

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  /// Handles the final account creation and profile setup
  void _finishSignup() async {
    // 1. Validate inputs
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      _showErrorMessage("Please enter your weight and height");
      return;
    }

    setState(() => _isLoading = true);
    
    // Parse controllers to double
    double weight = double.tryParse(_weightController.text) ?? 0.0;
    double height = double.tryParse(_heightController.text) ?? 0.0;

    try {
      // 2. Create Firebase account and Firestore document including 'name'
      // This step ensures the UserModel in Firestore has all required getters
      final user = await _auth.signUpUser(
        name: widget.name, 
        email: widget.email,
        password: widget.password,
        goal: widget.selectedGoal,
        weight: weight,
        height: height,
      );

      if (mounted) setState(() => _isLoading = false);

      if (user != null) {
        // 3. Clear navigation stack and enter the app on success
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) _showErrorMessage("Account creation failed. Check your internet or email.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage("Error: ${e.toString()}");
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Final Step"), 
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.speed_rounded, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  "Welcome, ${widget.name}!", 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Calibrating for: ${widget.selectedGoal}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 15),
                const Text(
                  "This helps calculate your BMI and set your starting AI intensity.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                
                // Weight Input
                TextField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: "Current Weight (kg)",
                    hintText: "e.g. 75.5",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Colors.green),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                
                // Height Input
                TextField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: "Height (cm)",
                    hintText: "e.g. 180",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.height_rounded, color: Colors.green),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 40),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _finishSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Create My Smart Plan", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}