import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';
import 'exercise_screen.dart'; 
import 'exercise_library_screen.dart'; 

class CustomWorkoutsScreen extends StatelessWidget {
  const CustomWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Premium Light Background
      appBar: AppBar(
        title: const Text("My Routines", style: TextStyle(fontWeight: FontWeight.w900, color: Color.fromARGB(255, 0, 0, 0))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FB),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExerciseLibraryScreen(
                isSelectionMode: true, 
              ),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 59, 150, 64),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Create New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<UserModel?>(
        stream: db.streamUserData(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
          }
          
          if (!snapshot.hasData || snapshot.data!.customWorkouts.isEmpty) {
            return _buildEmptyState();
          }

          final workouts = snapshot.data!.customWorkouts; 

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 90), 
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = Map<String, dynamic>.from(workouts[index]);
              final List dynamicExercises = (workout['exercises'] ?? []).whereType<Map>().toList();
              
              if (dynamicExercises.isEmpty) return const SizedBox.shrink();

              // Generate preview string (e.g., "Bench Press, Squat, +2 more")
              String previewText = dynamicExercises.take(3).map((e) => e['name']?.toString() ?? "Exercise").join(", ");
              if (dynamicExercises.length > 3) previewText += ", +${dynamicExercises.length - 3} more";

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _viewRoutineDetails(context, db, uid, workout, snapshot.data!.goal),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9), // Light Green
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF2E7D32), size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workout['title'] ?? "Untitled Routine", 
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _infoChip(Icons.layers_outlined, "${dynamicExercises.length} Exercises"),
                                        const SizedBox(width: 8),
                                        _infoChip(Icons.calendar_today_outlined, _formatDate(workout['createdAt'])),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showDeleteDialog(context, db, uid, workout),
                                child: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text("INCLUDES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text(
                            previewText,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF43A047), Color.fromARGB(255, 82, 162, 86)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFF43A047).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text("START SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _viewRoutineDetails(BuildContext context, DatabaseService db, String uid, Map<String, dynamic> workout, String userGoal) {
    List<ExerciseModel> exercises = (workout['exercises'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ExerciseModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    
    final Set<String> completedIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50, height: 5, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout['title'] ?? "Routine", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("${exercises.length} Exercises", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ExerciseLibraryScreen(isSelectionMode: true, routineToEdit: workout)),
                        );
                      }, 
                      icon: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.edit_rounded, color: Color(0xFF2E7D32))),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: exercises.length,
                  itemBuilder: (context, idx) {
                    final exercise = exercises[idx];
                    final isDone = completedIds.contains(exercise.id);

                    return Dismissible(
                      key: Key(exercise.id + idx.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _removeExerciseFromRoutine(db, uid, workout['title'], exercises, idx);
                        setModalState(() {
                          exercises.removeAt(idx);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${exercise.name} removed"), behavior: SnackBarBehavior.floating));
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.delete_rounded, color: Colors.red.shade700),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFF1F8E9) : Colors.white, // Subtle green tint if done
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDone ? const Color(0xFFA5D6A7) : Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDone ? const Color(0xFFC8E6C9) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Icon(isDone ? Icons.check : Icons.fitness_center, color: isDone ? const Color(0xFF2E7D32) : Colors.grey.shade500, size: 20),
                          ),
                          title: Text(exercise.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? Colors.grey : Colors.black87)),
                          subtitle: Text("${exercise.bodyPart}", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => ExerciseScreen(exercise: exercise, userGoal: userGoal)),
                            );
                            setModalState(() {
                              completedIds.add(exercise.id);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await _finishEntireRoutine(context, db, uid, workout['title'] ?? "Custom Routine");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text("COMPLETE ROUTINE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeExerciseFromRoutine(DatabaseService db, String uid, String title, List<ExerciseModel> currentList, int indexToRemove) async {
    List<ExerciseModel> updatedList = List.from(currentList);
    updatedList.removeAt(indexToRemove);
    await db.updateCustomWorkoutExercises(uid, title, updatedList);
  }

  Future<void> _finishEntireRoutine(BuildContext context, DatabaseService db, String uid, String routineTitle) async {
    try {
      await db.logExerciseSession(
        uid: uid, 
        exerciseName: "Routine: $routineTitle", 
        setWeights: [0.0], 
        reps: 0, 
        userBodyWeight: 0.0
      );

      await db.updateUserWorkoutStats(uid: uid, incrementWorkoutCount: true);

      if (context.mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Routine '$routineTitle' Completed!", style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to log completion.")));
    }
  }

  void _showDeleteDialog(BuildContext context, DatabaseService db, String uid, Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Routine?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("This action cannot be undone for '${workout['title']}'.", style: TextStyle(color: Colors.grey[600])),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              await db.deleteCustomWorkout(uid, workout);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0, foregroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.playlist_add_rounded, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text("No Routines Yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Tap 'Create New' to build your\nperfect workout plan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }

  String _formatDate(dynamic isoDate) {
    if (isoDate == null) return "Recently";
    try {
      DateTime dt = DateTime.parse(isoDate.toString());
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "Recently";
    }
  }
}