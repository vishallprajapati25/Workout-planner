import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart'; // Ensure shimmer is added to pubspec.yaml
import '../models/exercise_model.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ExerciseModel exercise;
  final Widget? trailing; // Support for custom icons/checkmarks

  const WorkoutCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.exercise,
    this.trailing, // Optional trailing widget
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // Use withValues instead of withOpacity for Flutter 3.27+ compatibility
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.grey[200],
            child: CachedNetworkImage(
              imageUrl: exercise.gifUrl,
              httpHeaders: const {
                'x-rapidapi-key': '6e5cb7db0cmsh7f9e92cbaec50b7p1a684ejsn61f3786cd8b5',
                'x-rapidapi-host': 'exercisedb.p.rapidapi.com',
              },
              fit: BoxFit.cover,
              // Animated shimmer effect while the GIF is downloading
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => 
                const Icon(Icons.fitness_center, color: Colors.green),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        // Displays custom trailing widget (like checkmark) or defaults to arrow
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}