import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Centralizes Supabase initialization and all read-only data access.
///
/// This app never writes to the backend, so we only ever call `.select()`
/// queries. Combined with the read-only RLS policies in
/// `supabase_schema.sql`, this keeps the backend maintenance-free and safe
/// to expose with a public anon key.
class SupabaseConfig {
  SupabaseConfig._();

  // Real project values from Supabase Dashboard > Project Settings > API.
  // Note: supabaseAnonKey holds a "publishable key" (sb_publishable_...),
  // Supabase's newer replacement for the legacy JWT anon key. It's a
  // drop-in for the `anonKey` parameter below and is meant to be public/
  // embedded client-side — Row Level Security is what actually protects
  // the data (see the read-only policies in supabase_schema.sql).
  static const String supabaseUrl = 'https://sillarmlltrsukqcnjni.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_psrR0OLzg5VcocWh_FcxGQ_870KDia1';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Fetches all PT categories for the dashboard grid.
  /// Throws a friendly [Exception] on network/timeout errors so the UI
  /// layer can show a retry state instead of a raw stack trace.
  static Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await client
          .from('categories')
          .select()
          .order('id')
          .timeout(const Duration(seconds: 10));

      return (response as List)
          .map((row) => CategoryModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
          'Could not load categories. Check your connection and try again.');
    }
  }

  /// Fetches exercises belonging to a specific category.
  static Future<List<ExerciseModel>> fetchExercisesByCategory(
      int categoryId) async {
    try {
      final response = await client
          .from('exercises')
          .select()
          .eq('category_id', categoryId)
          .order('id')
          .timeout(const Duration(seconds: 10));

      return (response as List)
          .map((row) => ExerciseModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
          'Could not load exercises for this category. Please try again.');
    }
  }
}
