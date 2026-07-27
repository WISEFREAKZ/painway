/// Data models mapping directly to the `categories` and `exercises`
/// Supabase tables. Every field is parsed defensively so a null or
/// malformed row from the network never crashes the UI.
library models;

class CategoryModel {
  final int id;
  final String name;
  final String iconSlug;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconSlug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Untitled Category',
      iconSlug: json['icon_slug'] as String? ?? 'accessibility_new',
    );
  }
}

class ExerciseModel {
  final int id;
  final int categoryId;
  final String title;
  final List<String> targetMuscles;
  final String description;
  final List<String> steps;
  final String? mediaUrl;
  final int durationSeconds;

  ExerciseModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.targetMuscles,
    required this.description,
    required this.steps,
    required this.mediaUrl,
    required this.durationSeconds,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      title: (json['title'] as String?) ?? 'Untitled Exercise',
      targetMuscles: _asStringList(json['target_muscles']),
      description: (json['description'] as String?) ?? '',
      steps: _asStringList(json['steps']),
      mediaUrl: json['media_url'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 30,
    );
  }

  /// Supabase returns Postgres text[] columns as a List<dynamic>.
  /// This helper safely coerces that (or a null) into a List<String>.
  static List<String> _asStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
