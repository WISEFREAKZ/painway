import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/supabase_config.dart';
import '../theme.dart';
import 'exercise_list_screen.dart';

/// Screen A — Dashboard & Habit Tracker.
///
/// Shows a daily water/stretch checklist (persisted locally with
/// SharedPreferences and reset each new calendar day), a settings sheet
/// to configure reminders, and a category grid pulled from Supabase.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _kWaterCountKey = 'habit_water_count';
  static const _kStretchDoneKey = 'habit_stretch_done';
  static const _kLastResetDateKey = 'habit_last_reset_date';
  static const _kWaterEnabledKey = 'pref_water_enabled';
  static const _kStretchEnabledKey = 'pref_stretch_enabled';
  static const _kStretchHourKey = 'pref_stretch_hour';
  static const _kStretchMinuteKey = 'pref_stretch_minute';

  static const int _dailyWaterGoal = 6; // glasses

  late Future<List<CategoryModel>> _categoriesFuture;

  int _waterCount = 0;
  bool _stretchDone = false;
  bool _waterEnabled = true;
  bool _stretchEnabled = true;
  TimeOfDay _stretchTime = const TimeOfDay(hour: 7, minute: 30);

  @override
  void initState() {
    super.initState();
    _categoriesFuture = SupabaseConfig.fetchCategories();
    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final lastReset = prefs.getString(_kLastResetDateKey);

    // Reset the daily checklist automatically when the calendar day rolls
    // over — the whole point of a lightweight habit tracker.
    if (lastReset != todayKey) {
      await prefs.setInt(_kWaterCountKey, 0);
      await prefs.setBool(_kStretchDoneKey, false);
      await prefs.setString(_kLastResetDateKey, todayKey);
    }

    setState(() {
      _waterCount = prefs.getInt(_kWaterCountKey) ?? 0;
      _stretchDone = prefs.getBool(_kStretchDoneKey) ?? false;
      _waterEnabled = prefs.getBool(_kWaterEnabledKey) ?? true;
      _stretchEnabled = prefs.getBool(_kStretchEnabledKey) ?? true;
      _stretchTime = TimeOfDay(
        hour: prefs.getInt(_kStretchHourKey) ?? 7,
        minute: prefs.getInt(_kStretchMinuteKey) ?? 30,
      );
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _incrementWater() async {
    if (_waterCount >= _dailyWaterGoal) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _waterCount++);
    await prefs.setInt(_kWaterCountKey, _waterCount);
  }

  Future<void> _toggleStretchDone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _stretchDone = !_stretchDone);
    await prefs.setBool(_kStretchDoneKey, _stretchDone);
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSettingsSheet(
        initialWaterEnabled: _waterEnabled,
        initialStretchEnabled: _stretchEnabled,
        initialStretchTime: _stretchTime,
        onSaved: (waterEnabled, stretchEnabled, stretchTime) async {
          setState(() {
            _waterEnabled = waterEnabled;
            _stretchEnabled = stretchEnabled;
            _stretchTime = stretchTime;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kWaterEnabledKey, waterEnabled);
          await prefs.setBool(_kStretchEnabledKey, stretchEnabled);
          await prefs.setInt(_kStretchHourKey, stretchTime.hour);
          await prefs.setInt(_kStretchMinuteKey, stretchTime.minute);

          final notifications = NotificationService();
          await notifications.requestPermissions();

          if (waterEnabled) {
            await notifications.scheduleWaterReminders();
          } else {
            await notifications.cancelWaterReminders();
          }

          if (stretchEnabled) {
            await notifications.scheduleStretchReminder(stretchTime);
          } else {
            await notifications.cancelStretchReminder();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Reminder settings',
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _categoriesFuture = SupabaseConfig.fetchCategories());
          await _categoriesFuture;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHabitTracker(),
            const SizedBox(height: 24),
            Text(
              'Choose a routine',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitTracker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's habits",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: AppColors.mutedBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Water · $_waterCount/$_dailyWaterGoal glasses'),
                ),
                OutlinedButton(
                  onPressed:
                      _waterCount >= _dailyWaterGoal ? null : _incrementWater,
                  child: const Text('+1'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (_waterCount / _dailyWaterGoal).clamp(0.0, 1.0),
              backgroundColor: AppColors.slate100,
              color: AppColors.mutedBlue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _toggleStretchDone,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(
                    _stretchDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _stretchDone
                        ? AppColors.calmTeal
                        : AppColors.slate400,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Morning stretch routine completed'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _ErrorRetry(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _categoriesFuture = SupabaseConfig.fetchCategories(),
            ),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No categories yet.'),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryTile(category: category);
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  const _CategoryTile({required this.category});

  IconData _iconFor(String slug) {
    switch (slug) {
      case 'foot_icon':
        return Icons.directions_walk;
      case 'hip_icon':
        return Icons.accessibility_new;
      case 'lowerback_icon':
        return Icons.airline_seat_flat;
      case 'knee_icon':
        return Icons.directions_run;
      case 'shoulder_icon':
        return Icons.sports_gymnastics;
      case 'neck_icon':
        return Icons.face_retouching_natural;
      case 'arms_icon':
        return Icons.fitness_center;
      case 'legs_icon':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseListScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.calmTealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(category.iconSlug),
                    color: AppColors.calmTeal),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.slate400, size: 32),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Bottom sheet for toggling reminders and picking the stretch time.
class _ReminderSettingsSheet extends StatefulWidget {
  final bool initialWaterEnabled;
  final bool initialStretchEnabled;
  final TimeOfDay initialStretchTime;
  final Future<void> Function(bool water, bool stretch, TimeOfDay time)
      onSaved;

  const _ReminderSettingsSheet({
    required this.initialWaterEnabled,
    required this.initialStretchEnabled,
    required this.initialStretchTime,
    required this.onSaved,
  });

  @override
  State<_ReminderSettingsSheet> createState() =>
      _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet> {
  late bool _waterEnabled;
  late bool _stretchEnabled;
  late TimeOfDay _stretchTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _waterEnabled = widget.initialWaterEnabled;
    _stretchEnabled = widget.initialStretchEnabled;
    _stretchTime = widget.initialStretchTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _stretchTime,
    );
    if (picked != null) setState(() => _stretchTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder settings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Water reminders'),
              subtitle: const Text('Every 2 hours, 8 AM – 8 PM'),
              value: _waterEnabled,
              onChanged: (v) => setState(() => _waterEnabled = v),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Morning stretch reminder'),
              subtitle: Text('Daily at ${_stretchTime.format(context)}'),
              value: _stretchEnabled,
              onChanged: (v) => setState(() => _stretchEnabled = v),
            ),
            if (_stretchEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Change time'),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSaved(
                          _waterEnabled,
                          _stretchEnabled,
                          _stretchTime,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
