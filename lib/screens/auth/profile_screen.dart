// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/fitness_calculator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // --- Premium Palette ---
  final Color _primaryColor = const Color(0xFF0F9D58); 
  final Color _darkGreen = const Color(0xFF054D2B);
  final Color _accentOrange = const Color(0xFFFFAB40);
  final Color _accentBlue = const Color(0xFF448AFF);
  final Color _bgLight = const Color(0xFFF4F6F9);

  Map<String, dynamic> _getBMICategory(double bmi) {
    if (bmi < 18.5) return {"label": "Underweight", "color": Colors.lightBlueAccent, "icon": Icons.sentiment_neutral};
    if (bmi < 25.0) return {"label": "Healthy", "color": const Color(0xFF69F0AE), "icon": Icons.check_circle}; // Bright Green
    if (bmi < 30.0) return {"label": "Overweight", "color": Colors.orangeAccent, "icon": Icons.warning_amber_rounded};
    return {"label": "Obese", "color": Colors.redAccent, "icon": Icons.warning_rounded};
  }

  void _showEditProfileModal(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final weightController = TextEditingController(text: user.weight.toString());
    final heightController = TextEditingController(text: user.height.toString());
    final targetWeightController = TextEditingController(text: (user.targetWeight ?? user.weight).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text("Edit Biometrics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              _buildUltraField(nameController, "Full Name", Icons.person),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildUltraField(weightController, "Current (kg)", Icons.monitor_weight)),
                const SizedBox(width: 16),
                Expanded(child: _buildUltraField(targetWeightController, "Target (kg)", Icons.flag)),
              ]),
              const SizedBox(height: 16),
              _buildUltraField(heightController, "Height (cm)", Icons.height),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: _primaryColor,
                  // ignore: deprecated_member use
                  shadowColor: _primaryColor.withOpacity(0.4),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  await _db.updateProfile(
                    _uid,
                    name: nameController.text,
                    weight: double.tryParse(weightController.text) ?? user.weight,
                    height: double.tryParse(heightController.text) ?? user.height,
                    targetWeight: double.tryParse(targetWeightController.text) ?? user.targetWeight,
                    goal: user.goal
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text("Save Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltraField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: label.contains("Full") ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 13),
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.logout, color: Colors.white, size: 18),
            ),
            onPressed: () async {
              await _auth.logout();
              if(!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getWeightHistoryStream(_uid),
        builder: (context, weightSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _db.getWorkoutHistoryStream(_uid),
            builder: (context, historySnapshot) {
              return FutureBuilder<UserModel?>(
                future: _db.getUserData(_uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!userSnapshot.hasData) return const Center(child: Text("No Data"));

                  final user = userSnapshot.data!;
                  final weightDocs = weightSnapshot.data?.docs ?? [];
                  final historyDocs = historySnapshot.data?.docs ?? [];

                  double dailyBurn = 0;
                  DateTime today = DateTime.now();
                  for (var doc in historyDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    if (ts.day == today.day && ts.month == today.month && ts.year == today.year) {
                      dailyBurn += (data['caloriesBurned'] ?? 0).toDouble();
                    }
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // --- 1. HERO HEADER (No Image, Vibrant Stats) ---
                        _buildHeroHeader(user, dailyBurn),
                        
                        Transform.translate(
                          offset: const Offset(0, -40), 
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- 2. WEIGHT TARGET CARD (With Shadow Glow) ---
                                if (weightDocs.isNotEmpty)
                                  _buildWeightTargetCard(weightDocs, user.targetWeight ?? user.weight),
                                
                                const SizedBox(height: 24),
                                _buildCalorieChart(historyDocs),
                                
                                const SizedBox(height: 30),
                                const Padding(
                                  padding: EdgeInsets.only(left: 8, bottom: 15),
                                  child: Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                                ),
                                _buildActivityList(historyDocs),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- 1. HERO HEADER (Clean & Vibrant) ---
  Widget _buildHeroHeader(UserModel user, double dailyBurn) {
    double bmi = FitnessCalculator.calculateBMI(user.weight, user.height);
    Map<String, dynamic> status = _getBMICategory(bmi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_darkGreen, _primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        // ignore: deprecated member use
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          // Greeting & BMI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello, ${user.name.split(' ')[0]}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      // ignore: deprecated_member use
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status['icon'], color: status['color'], size: 16),
                          const SizedBox(width: 8),
                          Text("BMI ${bmi.toStringAsFixed(1)} • ${status['label']}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileModal(user), 
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  // ignore: deprecated_member use
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                )
              )
            ],
          ),
          const SizedBox(height: 40),
          
          // --- VIBRANT STATS ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroStat("BURNED", "${dailyBurn.toInt()}", "kcal", _accentOrange), // Orange for Burn
              Container(height: 40, width: 1, color: Colors.white12),
              _heroStat("STREAK", "${user.streakCount}", "days", _accentBlue),   // Blue for Streak
              Container(height: 40, width: 1, color: Colors.white12),
              _heroStat("WEIGHT", "${user.weight}", "kg", Colors.white),         // White for Weight
            ],
          )
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, String unit, Color valueColor) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: valueColor, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  // --- 2. TARGET WEIGHT CARD (With Glow Shadow) ---
  Widget _buildWeightTargetCard(List<QueryDocumentSnapshot> docs, double targetWeight) {
    double current = (docs.last['weight'] as num).toDouble();
    double start = (docs.first['weight'] as num).toDouble();
    double totalToChange = (targetWeight - start).abs();
    double currentlyChanged = (current - start).abs();
    double progress = totalToChange == 0 ? 1.0 : (currentlyChanged / totalToChange).clamp(0.0, 1.0);

    List<FlSpot> spots = docs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble())).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w700)),
                  Text("$current kg", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Goal", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w700)),
                  Text("$targetWeight kg", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(height: 12, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6))),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12, 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _accentOrange]), // Vibrant gradient
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))] // Glow effect
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text("${(progress * 100).toInt()}% Achieved", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // --- SHADOW GLOW LINE ---
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    shadow: const Shadow(color: Colors.greenAccent, blurRadius: 10, offset: Offset(0, 4)), // The requested shadow
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.2), Colors.white.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                  // Dotted Target Line
                  LineChartBarData(
                    spots: [FlSpot(0, targetWeight), FlSpot((spots.length - 1).toDouble(), targetWeight)],
                    dashArray: [5, 5],
                    color: Colors.grey.withOpacity(0.3),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CALORIE CHART (Pill Design) ---
  Widget _buildCalorieChart(List<QueryDocumentSnapshot> docs) {
    Map<int, double> weekData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    double total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      if (DateTime.now().difference(date).inDays < 7) {
        double val = (data['caloriesBurned'] ?? 0).toDouble();
        weekData[date.weekday] = (weekData[date.weekday] ?? 0) + val;
        total += val;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Weekly Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                  Text("Total: ${total.toInt()} kcal", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle), child: const Icon(Icons.local_fire_department_rounded, color: Colors.orange))
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                barGroups: weekData.entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      gradient: LinearGradient(colors: [_primaryColor, _primaryColor.withOpacity(0.6)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                      width: 14,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(show: true, toY: 600, color: const Color(0xFFF5F7FA)),
                    )
                  ]
                )).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    int idx = v.toInt() - 1;
                    if(idx < 0 || idx >= 7) return const SizedBox();
                    return Padding(padding: const EdgeInsets.only(top: 12), child: Text(days[idx], style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)));
                  }, reservedSize: 30)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. ACTIVITY TILES (Floating) ---
  Widget _buildActivityList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No records yet.", style: TextStyle(color: Colors.grey))));
    
    return Column(
      children: docs.take(5).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.fitness_center_rounded, color: _primaryColor, size: 22),
            ),
            title: Text(data['exerciseName'] ?? "Workout", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
            subtitle: Text(DateFormat('MMM dd • h:mm a').format(date), style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("+${data['caloriesBurned'] ?? 0} kcal", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}