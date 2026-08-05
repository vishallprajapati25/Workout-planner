import 'package:flutter/material.dart';
import '../../../utils/app_constants.dart';
import 'body_stats_screen.dart'; 

class GoalSelectionScreen extends StatefulWidget {
  final String name; 
  final String email;
  final String password;
  
  const GoalSelectionScreen({
    super.key, 
    required this.name, 
    required this.email, 
    required this.password
  });

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String _selectedGoal = AppConstants.goalKeepFit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 1. HEADER DECORATION ---
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // --- 2. MAIN CONTENT CARD ---
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            child: Column(
              children: [
                const Text("Choose Your Path", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Text("This calibrates your AI workout plan", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                const SizedBox(height: 40),

                // --- 3. GOAL SELECTION LIST ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                  ),
                  child: Column(
                    children: [
                      // Progress Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3))),
                        child: const Text("Step 2 of 3", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                      const SizedBox(height: 30),

                      _buildPremiumGoalCard(AppConstants.goalWeightLoss, "Burn Fat & Lose Weight", Icons.local_fire_department_rounded, Colors.orange),
                      const SizedBox(height: 16),
                      _buildPremiumGoalCard(AppConstants.goalMuscleGain, "Build Muscle & Strength", Icons.fitness_center_rounded, Colors.blue),
                      const SizedBox(height: 16),
                      _buildPremiumGoalCard(AppConstants.goalKeepFit, "Keep Fit & Stay Healthy", Icons.spa_rounded, Colors.green),
                      
                      const SizedBox(height: 35),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BodyStatsScreen(
                                  name: widget.name,
                                  email: widget.email,
                                  password: widget.password,
                                  selectedGoal: _selectedGoal,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            elevation: 8,
                            shadowColor: const Color(0xFF00C853).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGoalCard(String goal, String subtitle, IconData icon, Color color) {
    bool isSelected = _selectedGoal == goal;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200, 
            width: isSelected ? 2.5 : 1.5
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] 
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade500, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isSelected ? Colors.black87 : Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle_rounded, color: color, size: 28)
          ],
        ),
      ),
    );
  }
}