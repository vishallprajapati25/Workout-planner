import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../services/database_service.dart';
import '../../models/exercise_model.dart';
import 'exercise_screen.dart'; 

class ExerciseLibraryScreen extends StatefulWidget {
  final bool isSelectionMode; 
  final Map<String, dynamic>? routineToEdit;

  const ExerciseLibraryScreen({
    super.key, 
    this.isSelectionMode = false, 
    this.routineToEdit
  });

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final DatabaseService _db = DatabaseService();
  
  final List<ExerciseModel> _selectedExercises = [];
  final _titleController = TextEditingController();
  
  String _searchQuery = "";
  String _selectedCategory = "All"; 
  bool _isSaving = false;
  bool _isEditMode = false;

  final List<String> _categories = [
    "All", "Chest", "Back", "Biceps", "Triceps", "Shoulders", "Legs", "Abs", "Cardio"
  ];

  bool get _isBuilderActive => widget.isSelectionMode || widget.routineToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.routineToEdit != null) {
      _isEditMode = true;
      _titleController.text = widget.routineToEdit!['title'] ?? "";
      
      final List rawExercises = widget.routineToEdit!['exercises'] ?? [];
      for (var ex in rawExercises) {
        if (ex is Map) {
          _selectedExercises.add(ExerciseModel.fromMap(Map<String, dynamic>.from(ex)));
        }
      }
    }
  }

  void _toggleSelection(ExerciseModel exercise) {
    setState(() {
      final isAlreadySelected = _selectedExercises.any((e) => e.id == exercise.id);
      if (isAlreadySelected) {
        _selectedExercises.removeWhere((e) => e.id == exercise.id);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  void _navigateToDetails(ExerciseModel exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(exercise: exercise, userGoal: "General"),
      ),
    );
  }

  void _cancelSelection() {
    if (widget.isSelectionMode || _isEditMode) {
      Navigator.pop(context);
    } else {
      setState(() {
        _selectedExercises.clear();
        _titleController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _saveRoutine() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Please enter a name for your routine.");
      return;
    }
    if (_selectedExercises.isEmpty) {
      _showSnackBar("Please select at least one exercise.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      
      if (_isEditMode) {
        await _db.updateCustomWorkoutExercises(uid, _titleController.text.trim(), _selectedExercises);
        _showSnackBar("Routine updated successfully!", isError: false);
      } else {
        await _db.createCustomWorkout(uid, _titleController.text.trim(), _selectedExercises);
        _showSnackBar("Workout saved to Custom tab!", isError: false);
      }
      
      if (mounted) {
        if (_isBuilderActive) {
          Navigator.pop(context); 
        } else {
          _cancelSelection(); 
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      _showSnackBar("Failed to save workout.");
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00C853), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = "Exercise Library";
    if (_isEditMode) {
      title = "Editing Routine";
    // ignore: curly_braces_in_flow_control_structures
    } else if (widget.isSelectionMode) title = "Select Exercises";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Premium Light Grey
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color.fromARGB(255, 0, 0, 0))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FB),
        leading: _isBuilderActive 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context))
          : null,
        actions: [
          if (_isBuilderActive || _selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: _cancelSelection,
                child: const Text("Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            )
        ],
      ),
      body: Column(
        children: [
          // --- 1. PREMIUM SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search for exercises...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color.fromARGB(255, 1, 174, 73)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          
          // --- 2. MODERN CATEGORY CHIPS ---
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF2E7D32) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      boxShadow: isSelected 
                        ? [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                        : [],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- 3. PREMIUM EXERCISE LIST ---
          Expanded(
            child: FutureBuilder<List<ExerciseModel>>(
              future: _db.getExercises(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text("No exercises found", style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                final displayList = snapshot.data!.where((ex) {
                  final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == "All" || ex.bodyPart.toLowerCase() == _selectedCategory.toLowerCase();
                  return matchesSearch && matchesCategory;
                }).toList();
                
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, _isBuilderActive || _selectedExercises.isNotEmpty ? 180 : 40),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final ex = displayList[index];
                    final isSelected = _selectedExercises.any((e) => e.id == ex.id);

                    return GestureDetector(
                      onTap: () {
                        if (_isBuilderActive) {
                          _toggleSelection(ex);
                        } else {
                          _navigateToDetails(ex);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? Border.all(color: const Color(0xFF00C853), width: 1.5) : null,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            // Exercise Icon/Image Placeholder
                            Container(
                              height: 60, width: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: NetworkImage(ex.gifUrl),
                                  fit: BoxFit.cover,
                                  onError: (e, s) => {},
                                )
                              ),
                              child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF2E7D32), size: 26),
                            ),
                            const SizedBox(width: 16),
                            
                            // Text Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: Text(ex.bodyPart, style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text("•  ${ex.difficulty}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Icon
                            Container(
                              height: 32, width: 32,
                              decoration: BoxDecoration(
                                color: _isBuilderActive 
                                  ? (isSelected ? const Color(0xFF00C853) : Colors.grey.shade100)
                                  : Colors.white,
                                shape: BoxShape.circle,
                                border: _isBuilderActive ? null : Border.all(color: Colors.grey.shade200),
                              ),
                              child: Icon(
                                _isBuilderActive ? Icons.check : Icons.arrow_forward_ios_rounded, 
                                size: 16, 
                                color: _isBuilderActive 
                                  ? (isSelected ? Colors.white : Colors.grey.shade400)
                                  : Colors.grey.shade400
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: (_isBuilderActive || _selectedExercises.isNotEmpty) ? _buildBottomBar() : null,
    );
  }

  // --- 4. POLISHED BOTTOM SHEET ---
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))], 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? "Update Routine Name" : "Name Your Routine", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            enabled: !_isEditMode, 
            inputFormatters: [LengthLimitingTextInputFormatter(25)],
            decoration: InputDecoration(
              hintText: "e.g. Chest Destroyer",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _cancelSelection,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditMode ? "Save Changes" : "Create Routine", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}