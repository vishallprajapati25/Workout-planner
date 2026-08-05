class ExerciseModel {
  final String id;
  final String name;
  final String gifUrl;
  final String bodyPart;
  final String difficulty;
  final String targetedPart;
  final String description;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.gifUrl,
    required this.bodyPart,
    required this.difficulty,
    required this.targetedPart,
    required this.description,
  });

  /// Factory to map data from Firestore (Lean) or ExerciseDB API (Rich)
  factory ExerciseModel.fromMap(Map<String, dynamic> data, {String? customId}) {
    
    /// Helper to handle the "instructions" field from the API.
    /// The API returns a List of strings, but Firestore might store a single String.
    String parseDescription(dynamic desc) {
      if (desc is List) {
        return desc.join("\n"); // Each instruction step on a new line
      }
      return desc?.toString() ?? 'Instructions will be loaded from the live API...';
    }

    return ExerciseModel(
      // The 4-digit ID is crucial for the Dynamic GIF fetching
      id: data['id']?.toString() ?? customId ?? '',
      
      name: data['name'] ?? 'Unknown Exercise',
      
      // gifUrl might be empty in Firestore; it gets fetched live in ExerciseScreen
      gifUrl: data['gifUrl'] ?? '',
      
      bodyPart: (data['bodyPart'] ?? 'general').toString().toLowerCase(),
      
      difficulty: data['difficulty'] ?? 'Intermediate',
      
      // API key is 'target', Firestore key might be 'targetedPart'
      targetedPart: (data['target'] ?? data['targetedPart'] ?? 'General').toString(),
      
      // API key is 'instructions', Firestore key might be 'description'
      description: parseDescription(data['instructions'] ?? data['description']),
    );
  }

  /// Helper for UI to capitalize body parts (e.g., 'back' -> 'Back')
  String get displayBodyPart => bodyPart.isNotEmpty 
      ? bodyPart[0].toUpperCase() + bodyPart.substring(1) 
      : 'General';

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'name': name,
      'gifUrl': gifUrl,
      'bodyPart': bodyPart,
      'difficulty': difficulty,
      'targetedPart': targetedPart,
      'description': description,
    };
  }
}