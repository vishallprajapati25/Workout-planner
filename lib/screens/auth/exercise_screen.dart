import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; 
import '../../models/exercise_model.dart';
import '../../models/user_model.dart';
import '../../utils/workout_helpers.dart';
import '../../services/database_service.dart';

class ExerciseScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final String userGoal;

  const ExerciseScreen({super.key, required this.exercise, required this.userGoal});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final DatabaseService _db = DatabaseService();
  final String apiKey = '6e5cb7db0cmsh7f9e92cbaec50b7p1a684ejsn61f3786cd8b5';
  final String apiHost = 'exercisedb.p.rapidapi.com';

  int _currentSet = 1;
  late int _timerSeconds;
  Timer? _timer;
  bool _isResting = false;
  bool _hasStarted = false; 
  bool _isInstructionsExpanded = false; 

  UserModel? _userProfile;
  late List<double> _setWeights;
  late List<bool> _completedSets;

  ExerciseModel? _detailedExercise;
  Uint8List? _gifBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _refreshData(); 
    
    final config = WorkoutHelpers.getGoalConfiguration(widget.userGoal);
    final int totalSets = int.tryParse(config['sets'].toString()) ?? 3;
    
    _setWeights = List.generate(totalSets, (index) => 0.0);
    _completedSets = List.generate(totalSets, (index) => false);
    
    _resetTimer();
  }

  Future<void> _refreshData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://exercisedb.p.rapidapi.com/exercises/exercise/${widget.exercise.id}'),
        headers: {'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detailedModel = ExerciseModel.fromMap(data);
        final dynamicGifUrl = 'https://exercisedb.p.rapidapi.com/image?exerciseId=${widget.exercise.id}&resolution=360&rapidapi-key=$apiKey';
        final gifResponse = await http.get(Uri.parse(dynamicGifUrl), headers: {'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost});

        if (mounted) {
          setState(() {
            _detailedExercise = detailedModel;
            if (gifResponse.statusCode == 200) _gifBytes = gifResponse.bodyBytes;
            _isLoading = false;
          });
        }
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _loadInitialData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    UserModel? profile = await _db.getUserData(uid);
    if (mounted) {
      setState(() {
        _userProfile = profile;
        double historicalWeight = profile?.performanceHistory[widget.exercise.name]?.toDouble() ?? 0.0;
        _setWeights = List.generate(_setWeights.length, (index) => historicalWeight);
      });
    }
  }

  void _resetTimer() {
    final config = WorkoutHelpers.getGoalConfiguration(widget.userGoal);
    _timerSeconds = int.tryParse(config['rest'].toString()) ?? 60;
  }

  void _startRestTimer() {
    setState(() => _isResting = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else { _stopTimer(); }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted) {
      final config = WorkoutHelpers.getGoalConfiguration(widget.userGoal);
      final int maxSets = int.tryParse(config['sets'].toString()) ?? 3;
      setState(() {
        _isResting = false;
        _completedSets[_currentSet - 1] = true; 
        _resetTimer();
        _currentSet++;
      });
      if (_currentSet > maxSets) _handleManualSave();
    }
  }

  void _previousSet() {
    if (_currentSet > 1) {
      _timer?.cancel();
      setState(() {
        _isResting = false;
        _completedSets[_currentSet - 2] = false; 
        _resetTimer();
        _currentSet--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = WorkoutHelpers.getGoalConfiguration(widget.userGoal);
    final int totalSets = int.tryParse(config['sets'].toString()) ?? 3;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          title: Text(widget.exercise.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGifCard(),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- TARGETED PART BADGE ---
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.exercise.targetedPart.toUpperCase(),
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // --- HOW TO PERFORM (Simple Link style) ---
                              const Text("HOW TO PERFORM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                              const SizedBox(height: 6),
                              Text(
                                _detailedExercise?.description ?? "Loading guide...",
                                maxLines: _isInstructionsExpanded ? null : 2,
                                overflow: _isInstructionsExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700], height: 1.5),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isInstructionsExpanded = !_isInstructionsExpanded),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _isInstructionsExpanded ? "See Less" : "See More...",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),
                              
                              if (_hasStarted) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("WORKOUT LOG", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                                    Text("Goal: ${config['displayReps']} Reps", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSetList(config),
                              ],
                              
                              if (_isResting) _buildPremiumTimer(int.tryParse(config['rest'].toString()) ?? 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBottomActionBar(totalSets),
                ],
              ),
      ),
    );
  }

  Widget _buildGifCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _gifBytes != null 
          ? Image.memory(_gifBytes!, height: 260, fit: BoxFit.contain)
          : Container(height: 260, color: Colors.grey[50], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSetList(Map<String, dynamic> config) {
    final int maxSets = int.tryParse(config['sets'].toString()) ?? 3;
    return Column(
      children: List.generate(_currentSet.clamp(1, maxSets), (index) {
        bool isCurrent = _currentSet == (index + 1);
        bool isDone = _completedSets[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCurrent ? Colors.green : (isDone ? Colors.green.withOpacity(0.1) : Colors.grey.shade100), width: 2),
          ),
          child: Row(
            children: [
              Container(
                height: 32, width: 32,
                decoration: BoxDecoration(
                  color: isDone ? Colors.green : (isCurrent ? Colors.green.shade50 : Colors.grey[100]),
                  shape: BoxShape.circle
                ),
                child: Center(
                  child: isDone 
                    ? const Icon(Icons.check, color: Colors.white, size: 16) 
                    : Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.green : Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Weight", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  decoration: InputDecoration(
                    hintText: _setWeights[index].toString(),
                    suffixText: "kg",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => _setWeights[index] = double.tryParse(v) ?? 0.0,
                ),
              ),
              if (isCurrent && _currentSet > 1)
                IconButton(icon: const Icon(Icons.history_rounded, color: Colors.orangeAccent), onPressed: _previousSet),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPremiumTimer(int totalRest) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120, width: 120,
                child: CircularProgressIndicator(
                  value: _timerSeconds / totalRest,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  color: Colors.orangeAccent,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("$_timerSeconds", style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
            ],
          ),
          TextButton(onPressed: _stopTimer, child: const Text("SKIP REST", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(int totalSets) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (!_hasStarted) {
              setState(() => _hasStarted = true);
            } else if (!_isResting) {
              if (_currentSet > totalSets) {
                _handleManualSave();
              } else {
                _startRestTimer();
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isResting ? Colors.grey[200] : const Color(0xFF00C853),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: Text(
            !_hasStarted ? "START EXERCISE" : (_isResting ? "RECOVERY..." : (_currentSet > totalSets ? "FINISH EXERCISE" : "COMPLETE SET $_currentSet")),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  void _handleManualSave() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 60),
        content: const Text("Workout Complete! Ready to log your history?", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => _finalSessionWrite(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("Log Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _finalSessionWrite() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final config = WorkoutHelpers.getGoalConfiguration(widget.userGoal);
      final resultData = {'sets': _setWeights.length, 'weights': _setWeights};

      await _db.logExerciseSession(
        uid: uid, 
        exerciseName: widget.exercise.name, 
        setWeights: _setWeights, 
        reps: int.tryParse(config['reps'].toString()) ?? 12, 
        userBodyWeight: _userProfile?.weight ?? 0.0
      );
      await _db.updateUserWorkoutStats(uid: uid, incrementWorkoutCount: true);

      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context, resultData);
      }
    } catch (e) { debugPrint("Error writing session: $e"); }
  }
}