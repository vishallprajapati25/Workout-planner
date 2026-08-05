import 'package:flutter/material.dart';
import 'goal_selection_screen.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _continueToGoals() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) { _showError("Please enter your full name"); return; }
    if (email.isEmpty || !email.contains('@')) { _showError("Please enter a valid email address"); return; }
    if (password.length < 6) { _showError("Password must be at least 6 characters"); return; }
    if (password != _confirmPasswordController.text.trim()) { _showError("Passwords do not match"); return; }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalSelectionScreen(
          name: name, 
          email: email,
          password: password,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 1. VIBRANT HEADER ---
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00E676)], // Brighter, higher contrast green
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

          // --- 2. MAIN CONTENT ---
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text("Join us to start your journey", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w600)),
                const SizedBox(height: 35),

                // --- 3. HIGH CONTRAST FORM CARD ---
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))], // Deeper shadow
                  ),
                  child: Column(
                    children: [
                      // Progress Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)), // Added border
                        ),
                        child: const Text("Step 1 of 3", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                      const SizedBox(height: 30),
                      
                      _buildHighContrastTextField(_nameController, "Full Name", Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildHighContrastTextField(_emailController, "Email Address", Icons.email_outlined),
                      const SizedBox(height: 20),
                      _buildHighContrastTextField(_passwordController, "Password", Icons.lock_outline_rounded, isPassword: true),
                      const SizedBox(height: 20),
                      _buildHighContrastTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset_rounded, isPassword: true),
                      
                      const SizedBox(height: 35),
                      SizedBox(
                        width: double.infinity,
                        height: 60, // Taller button
                        child: ElevatedButton(
                          onPressed: _continueToGoals,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            elevation: 8, // Higher elevation for pop
                            shadowColor: const Color(0xFF00C853).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                      children: [
                        TextSpan(text: "Login", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighContrastTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), // Darker text
      textCapitalization: !isPassword ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: const Color(0xFF00C853), size: 24), // Green Icon
        filled: true,
        fillColor: const Color(0xFFF9FAFB), // Very light grey bg
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5), // Visible border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 2), // thicker green border on focus
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}