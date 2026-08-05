import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/exercise_model.dart';
import '../services/database_service.dart';

class AIService {
  static const String _apiKey = "AIzaSyDrLPdqBfUEmyZZR2P9EDRZXYPQcL9hpf4";
  late final GenerativeModel _model;
  final DatabaseService _db = DatabaseService();

  AIService() {
    final workoutSchema = Schema.array(
      items: Schema.object(
        properties: {
          'id': Schema.string(description: 'ID from the provided list'),
          'name': Schema.string(description: 'Exercise name exactly as provided'),
          'bodyPart': Schema.string(description: 'Main muscle group'),
          'targetedPart': Schema.string(description: 'Specific muscle'),
          'description': Schema.string(description: 'Step-by-step instructions'),
          'gifUrl': Schema.string(description: 'The gifUrl provided in the list'),
        },
        requiredProperties: ['id', 'name', 'bodyPart', 'targetedPart', 'description', 'gifUrl'],
      ),
    );

    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Note: gemini-2.0-flash is the current stable high-speed model
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: workoutSchema,
        temperature: 0.1,
      ),
    );
  }

  Future<List<ExerciseModel>> generateSmartPlan({
    required String goal,
    required double weight,
    required String userLevel, 
    required List<String> selectedMuscleGroups, 
  }) async {
    if (_apiKey.isEmpty) return [];

    try {
      List<ExerciseModel> library = await _db.getExercises();
      if (library.isEmpty) return [];

      // 1. DYNAMIC COUNT LOGIC
      // If selected muscle groups > 3 (Full Body), pick 1 per category (Total ~6)
      // If selected muscle groups <= 3 (Targeted), pick 3 per category (Total 3-9)
      final int perCategoryCount = selectedMuscleGroups.length > 3 ? 1 : 3;
      final int totalRequired = selectedMuscleGroups.length * perCategoryCount;

      // 2. STRICTOR POOL FILTERING
      List<ExerciseModel> filteredPool = library.where((ex) {
        return selectedMuscleGroups.any((group) => 
          ex.bodyPart.toLowerCase().trim() == group.toLowerCase().trim());
      }).toList();

      // 3. ORGANIZE DATA BY CATEGORY
      String organizedList = "";
      for (var group in selectedMuscleGroups) {
        organizedList += "\n=== CATEGORY: ${group.toUpperCase()} ===\n";
        organizedList += filteredPool
            .where((e) => e.bodyPart.toLowerCase().trim() == group.toLowerCase().trim())
            .map((e) => "- Name: ${e.name} | ID: ${e.id} | Targeted: ${e.targetedPart}")
            .join("\n");
      }

      final String partsLabel = selectedMuscleGroups.join(' & ').toUpperCase();

      // 4. REINFORCED PROMPT FOR FULL BODY & TARGETED
      final prompt = """
        You are a certified fitness trainer. Create a $userLevel level workout session for: $partsLabel.
        The goal is $goal.
        
        ONLY USE EXERCISES FROM THIS LIST:
        $organizedList

        CRITICAL SELECTION RULES:
        1. PER CATEGORY LIMIT: You MUST pick EXACTLY $perCategoryCount exercise(s) for EVERY '=== CATEGORY ===' header listed above.
        2. TOTAL COUNT: You must return exactly $totalRequired exercises in total.
        3. CATEGORY LOCK: Only pick exercises from within their respective '=== CATEGORY ===' section.
        4. DATA INTEGRITY: Return the exact Name and ID strings as provided in the list.
        5. ORDERING: Arrange the workout logically (e.g., large muscles like Legs/Back first, core/abs last).
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      final List<dynamic> decoded = jsonDecode(text);
      
      List<ExerciseModel> finalPlan = [];
      for (var item in decoded) {
        String aiPickedId = item['id'].toString().trim();
        
        // Match by ID for higher accuracy
        final exerciseFromLibrary = library.firstWhere(
          (ex) => ex.id.trim() == aiPickedId,
          orElse: () => ExerciseModel.fromMap(item as Map<String, dynamic>),
        );
        finalPlan.add(exerciseFromLibrary);
      }

      return finalPlan;
    } catch (e) {
      debugPrint("AI SELECTION ERROR: $e");
      return [];
    }
  }
}