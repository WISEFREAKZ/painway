import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_config.dart';
import '../theme.dart';
import 'exercise_guide_screen.dart';

/// Screen B — Exercise List View.
///
/// Queries Supabase for every exercise where `category_id` matches the
/// selected category and renders a fast, scannable list. Pass `category:
/// null` to show every exercise across all categories instead (used by
/// the "Workouts" tab).
class ExerciseListScreen extends StatefulWidget {
  final CategoryModel? category;
  const ExerciseListScreen({super.key, this.category});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  late Future<List<ExerciseModel>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _fetch();
  }

  Future<List<ExerciseModel>> _fetch() {
    final category = widget.category;
    return category == null
        ? SupabaseConfig.fetchAllExercises()
        : SupabaseConfig.fetchExercisesByCategory(category.id);
  }

  void _retry() {
    setState(() => _exercisesFuture = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category?.name ?? 'All Exercises')),
      body: FutureBuilder<List<ExerciseModel>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppColors.slate400, size: 32),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final exercises = snapshot.data ?? [];
          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises in this category yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ExerciseListTile(exercise: exercises[index]),
          );
        },
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExerciseListTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseGuideScreen(exercise: exercise),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _Thumbnail(url: exercise.mediaUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (exercise.targetMuscles.isNotEmpty)
                      Text(
                        exercise.targetMuscles.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small network-image thumbnail with graceful loading/error states so a
/// slow or dead external GIF link never breaks the list layout.
class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.slate100,
        child: const Icon(Icons.image_not_supported, color: AppColors.slate400),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.slate100,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.slate100,
        child: const Icon(Icons.image_not_supported, color: AppColors.slate400),
      ),
    );
  }
}
