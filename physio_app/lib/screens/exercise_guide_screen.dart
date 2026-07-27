import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/circular_countdown.dart';

/// Screen C — Step-by-Step Interactive Guide.
///
/// Top viewport plays the exercise's looping media (`media_url`), below
/// which a horizontal PageView carousel walks through each instructional
/// step, and a circular countdown drives the timed hold/execution.
class ExerciseGuideScreen extends StatefulWidget {
  final ExerciseModel exercise;
  const ExerciseGuideScreen({super.key, required this.exercise});

  @override
  State<ExerciseGuideScreen> createState() => _ExerciseGuideScreenState();
}

class _ExerciseGuideScreenState extends State<ExerciseGuideScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCompletionSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nice work! Hold complete.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final steps = exercise.steps;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaViewport(exercise.mediaUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exercise.targetMuscles.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.targetMuscles
                          .map((m) => Chip(
                                label: Text(m),
                                backgroundColor: AppColors.calmTealLight,
                                labelStyle: const TextStyle(
                                  color: AppColors.slate900,
                                  fontSize: 12,
                                ),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                  if (exercise.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      exercise.description,
                      style: const TextStyle(color: AppColors.slate700, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (steps.isNotEmpty) _buildStepsCarousel(steps),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Hold / execute for',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  CircularCountdown(
                    durationSeconds: exercise.durationSeconds,
                    onComplete: _showCompletionSnackbar,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Prominent top viewport rendering the looping animated exercise
  /// demonstration, with an explicit loading builder so slow open-source
  /// GIF hosts never show a blank/broken frame.
  Widget _buildMediaViewport(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: AppColors.slate100,
        child: const Center(
          child: Icon(Icons.image_not_supported,
              color: AppColors.slate400, size: 40),
        ),
      );
    }

    return Image.network(
      mediaUrl,
      height: 260,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final total = loadingProgress.expectedTotalBytes;
        final loaded = loadingProgress.cumulativeBytesLoaded;
        return Container(
          height: 260,
          color: AppColors.slate100,
          child: Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
              strokeWidth: 2.5,
              color: AppColors.calmTeal,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: 260,
        color: AppColors.slate100,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: AppColors.slate400, size: 32),
              SizedBox(height: 6),
              Text(
                'Could not load animation',
                style: TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsCarousel(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Step ${_currentStep + 1} of ${steps.length}',
            style: const TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: steps.length,
            onPageChanged: (index) => setState(() => _currentStep = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.calmTeal,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              steps.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentStep ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _currentStep
                      ? AppColors.calmTeal
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
