import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

// Service & Model Imports
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';

// Utility & Widget Imports
import '../../utils/fitness_calculator.dart';
import '../../utils/workout_helpers.dart';

// Screen Imports
import 'exercise_screen.dart';
import 'profile_screen.dart';
import '../auth/exercise_library_screen.dart'; 
import '../auth/custom_workouts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const WorkoutDashboard(),
    const CustomWorkoutsScreen(),
    const ExerciseLibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), 
              blurRadius: 20, 
              offset: const Offset(0, -5)
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: const Color.fromARGB(255, 180, 175, 175),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.view_agenda_rounded), label: 'Custom'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Library'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class WorkoutDashboard extends StatefulWidget {
  const WorkoutDashboard({super.key});

  @override
  State<WorkoutDashboard> createState() => _WorkoutDashboardState();
}

class _WorkoutDashboardState extends State<WorkoutDashboard> {
  final DatabaseService _db = DatabaseService();
  final AIService _ai = AIService();

  UserModel? _userProfile;
  List<ExerciseModel> _aiWorkouts = [];
  
  bool _isInitialLoading = true;
  bool _isGenerating = false;    
  
  bool _isEditingGoalManually = false;

  // Stores sets/weights data
  final Map<String, Map<String, dynamic>> _completedLogs = {};

  final Map<String, List<String>> _workoutSplits = {
    "Full Body": ["chest", "back", "legs", "shoulders", "arms", "abs"],
    "Chest & Triceps": ["chest", "triceps"],
    "Back & Biceps": ["back", "biceps"],
    "Legs & Abs": ["legs", "abs"],
    "Shoulders & Cardio": ["shoulders", "cardio"],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      UserModel? profile = await _db.getUserData(uid);
      List<ExerciseModel>? todayWorkout = await _db.getPersistedDailyWorkout(uid);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          if (todayWorkout != null) _aiWorkouts = todayWorkout;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _selectGoal(String goal) async {
    setState(() => _isInitialLoading = true); 
    String uid = FirebaseAuth.instance.currentUser!.uid;
    
    await _db.updateProfile(
      uid, 
      name: _userProfile?.name ?? "User",
      weight: _userProfile?.weight ?? 0.0,
      height: _userProfile?.height ?? 0.0,
      goal: goal
    );
    
    setState(() {
      _isEditingGoalManually = false;
    });
    
    await _loadData(); 
  }

  Future<void> _finalizeFullSession() async {
    setState(() => _isInitialLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    
    await _db.updateUserWorkoutStats(uid: uid, incrementWorkoutCount: true);
    
    setState(() {
      _completedLogs.clear();
      _isInitialLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.emoji_events, color: Colors.white),
          SizedBox(width: 10),
          Text("Session Logged! Amazing work!"),
        ]),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) return const _SmartLoadingView();

    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00C853))),
      );
    }

    if (_userProfile == null) return const Scaffold(body: Center(child: Text("Error loading profile")));

    bool hasGoalInDatabase = _userProfile!.goal == "Weight Loss" || 
                             _userProfile!.goal == "Muscle Gain" || 
                             _userProfile!.goal == "Keep Fit";

    bool showDashboard = hasGoalInDatabase && !_isEditingGoalManually;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), 
      appBar: AppBar(
        // FIXED: Removed Icon from StayFit Hub
        title: const Text("StayFit Hub", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (showDashboard)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              // FIXED: Removed Icon from Change Goal Button
              child: TextButton(
                onPressed: () => setState(() => _isEditingGoalManually = true),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                child: Text("Change Goal", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF00C853),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: showDashboard ? _buildMainDashboard() : _buildGoalSelectionView(hasGoalInDatabase),
        ),
      ),
    );
  }

  Widget _buildGoalSelectionView(bool hasExistingGoal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text("Choose Your Path", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 8),
        Text("Select a goal to customize your plan.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        const SizedBox(height: 30),
        _buildGoalCard("Muscle Gain", "Hypertrophy & Strength", Icons.fitness_center, const Color(0xFF1E88E5)),
        _buildGoalCard("Keep Fit", "Tone & Maintenance", Icons.favorite, const Color(0xFF43A047)),
        _buildGoalCard("Weight Loss", "High Intensity Burn", Icons.local_fire_department, const Color(0xFFFB8C00)),
        
        if (hasExistingGoal) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _isEditingGoalManually = false),
              label: const Text("Return to Home", style: TextStyle(color: Color.fromARGB(255, 36, 35, 35), fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalCard(String title, String subtitle, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _selectGoal(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCircularProgressCard(),
        const SizedBox(height: 30),
        const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 15),
        _buildStatsRow(
          FitnessCalculator.calculateBMI(_userProfile!.weight, _userProfile!.height), 
          WorkoutHelpers.getGoalConfiguration(_userProfile!.goal)
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Session", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            if (_aiWorkouts.isNotEmpty)
              GestureDetector(
                onTap: _showSplitSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.sync, size: 16, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Text("Switch Split", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        _aiWorkouts.isEmpty ? _buildEmptyState() : _buildWorkoutList(),
        
        const SizedBox(height: 20),

        if (_completedLogs.length == _aiWorkouts.length && _aiWorkouts.isNotEmpty) 
          Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ElevatedButton.icon(
              onPressed: _finalizeFullSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100), 
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
              ),
              icon: const Icon(Icons.emoji_events_rounded, size: 28),
              label: const Text("COMPLETE & LOG SESSION", 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
          )
        else if (_aiWorkouts.isEmpty)
          _buildAIActionButton(),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCircularProgressCard() {
    double progress = 0.0;
    if (_aiWorkouts.isNotEmpty) {
      progress = _completedLogs.length / _aiWorkouts.length;
    }
    int percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)], 
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daily Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  progress == 1.0 ? "All done! Amazing job." : "Keep pushing forward!",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    progress == 1.0 ? "Completed" : "In Progress",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    ),
                  ),
                )
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80, width: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white, 
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$percentage%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(double bmi, Map<String, dynamic> config) {
    return Row(children: [
      _statBox("BMI", bmi.toStringAsFixed(1), Icons.monitor_weight_rounded, Colors.blue.shade50, Colors.blue.shade700),
      const SizedBox(width: 16),
      _statBox("Goal", _userProfile!.goal, Icons.track_changes_rounded, Colors.purple.shade50, Colors.purple.shade700),
      const SizedBox(width: 16),
      _statBox("Sets", "${config['sets']}", Icons.layers_rounded, Colors.orange.shade50, Colors.orange.shade700),
    ]);
  }

  Widget _statBox(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87), textAlign: TextAlign.center,),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  Widget _buildWorkoutList() {
    return ListView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: _aiWorkouts.length,
      itemBuilder: (c, i) {
        final ex = _aiWorkouts[i];
        final isCompleted = _completedLogs.containsKey(ex.id);
        final logData = _completedLogs[ex.id];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isCompleted ? Colors.transparent : Colors.black.withValues(alpha: 0.03), 
                blurRadius: 15, 
                offset: const Offset(0, 5)
              )
            ],
            border: isCompleted ? Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3), width: 1.5) : null,
          ),
          child: Opacity(
            opacity: isCompleted ? 0.6 : 1.0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                height: 56, width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(ex.gifUrl),
                    fit: BoxFit.cover,
                    onError: (e,s) => {}, 
                  )
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF2E7D32), size: 26),
              ),
              title: Text(ex.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isCompleted ? TextDecoration.lineThrough : null)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: isCompleted && logData != null 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIXED: Display set counts and weights in the subtitle
                        Text("${logData['sets']} Sets Completed", style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("Weights: ${(logData['weights'] as List).join(', ')} kg", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    )
                  : Row(
                      children: [
                        _tag(ex.bodyPart, Colors.blue.shade50, Colors.blue.shade700),
                        const SizedBox(width: 8),
                        _tag(ex.targetedPart, Colors.orange.shade50, Colors.orange.shade700),
                      ],
                    ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF00C853) : Colors.grey.shade100,
                  shape: BoxShape.circle
                ),
                child: Icon(isCompleted ? Icons.check : Icons.arrow_forward_ios, size: 18, color: isCompleted ? Colors.white : Colors.grey.shade400),
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (c) => ExerciseScreen(exercise: ex, userGoal: _userProfile!.goal))
                );
                
                // FIXED: Mark as completed and update weights/sets data on return
                if (result != null && result is Map) {
                  setState(() {
                    _completedLogs[ex.id] = {
                      'sets': result['sets'] ?? 0,
                      'weights': result['weights'] ?? []
                    };
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String text, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textC, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAIActionButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64), 
          backgroundColor:const Color.fromARGB(255, 59, 150, 64), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("Generate Balanced Split", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        onPressed: _showSplitSelector,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40), 
        child: Column(
          children: [
            Icon(Icons.fitness_center, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Ready to work?", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("Tap below to generate your workout.", style: TextStyle(color: Colors.grey.shade400)),
          ],
        )
      )
    );
  }

  void _showSplitSelector() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Target Muscle Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ..._workoutSplits.keys.map((split) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: ListTile(
                title: Text(split, style: const TextStyle(fontWeight: FontWeight.w600)), 
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.bolt_rounded, color: Colors.green.shade700, size: 20),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                onTap: () { 
                  Navigator.pop(c); 
                  _handleAIWorkoutGeneration(_workoutSplits[split]!); 
                }
              ),
            )),
          ],
        )
      ),
    );
  }

  Future<void> _handleAIWorkoutGeneration(List<String> muscleGroups) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) return;
    try {
      setState(() {
        _isGenerating = true; 
        _completedLogs.clear(); 
      });
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String level = (_userProfile?.workoutCount ?? 0) > 10 ? 'Intermediate' : 'Beginner';
      final plan = await _ai.generateSmartPlan(
        goal: _userProfile!.goal, 
        weight: _userProfile!.weight, 
        userLevel: level, 
        selectedMuscleGroups: muscleGroups
      );
      await _db.saveDailyWorkout(uid, plan);
      if (mounted) {
        setState(() { 
        _aiWorkouts = plan; 
        _isGenerating = false; 
      });
      }
    } catch (e) { 
      if (mounted) setState(() => _isGenerating = false); 
    }
  }
}

class _SmartLoadingView extends StatefulWidget {
  const _SmartLoadingView();

  @override
  State<_SmartLoadingView> createState() => _SmartLoadingViewState();
}

class _SmartLoadingViewState extends State<_SmartLoadingView> {
  int _tipIndex = 0;
  Timer? _timer;

  final List<String> _tips = [
    "Hydration is key! Drink water between sets.",
    "Form over weight. Always control the movement.",
    "Rest days are when your muscles actually grow.",
    "Consistent effort beats intensity every time.",
    "Focus on your breathing during every rep.",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    height: 80, width: 80,
                    child: CircularProgressIndicator(color: Color(0xFF00C853), strokeWidth: 6),
                  ),
                  Icon(Icons.auto_awesome, color: const Color(0xFF00C853).withValues(alpha: 0.8), size: 30),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                "Building Your Perfect Routine...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "Tip: ${_tips[_tipIndex]}",
                  key: ValueKey<int>(_tipIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}