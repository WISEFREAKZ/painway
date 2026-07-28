import 'dart:convert';
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
  static const _kHistoryKey = 'habit_history_v1';
  static const _kWaterEnabledKey = 'pref_water_enabled';
  static const _kStretchEnabledKey = 'pref_stretch_enabled';
  static const _kStretchHourKey = 'pref_stretch_hour';
  static const _kStretchMinuteKey = 'pref_stretch_minute';

  static const int _dailyWaterGoal = 6; // glasses
  static const int _historyDaysToShow = 7;

  late Future<List<CategoryModel>> _categoriesFuture;

  int _waterCount = 0;
  bool _stretchDone = false;
  bool _waterEnabled = true;
  bool _stretchEnabled = true;
  TimeOfDay _stretchTime = const TimeOfDay(hour: 7, minute: 30);

  // Day-key ('2026-07-29') -> {'water': int, 'stretch': bool}. This is
  // what actually makes the tracker a *tracker* rather than a single
  // checkbox that forgets everything at midnight — it's what powers the
  // weekly progress row and streak count below.
  Map<String, Map<String, dynamic>> _history = {};

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

    final historyRaw = prefs.getString(_kHistoryKey);
    Map<String, Map<String, dynamic>> history = {};
    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyRaw) as Map<String, dynamic>;
        history = decoded.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        );
      } catch (_) {
        // Corrupt/old-format data — start fresh rather than crash.
        history = {};
      }
    }

    // Roll the day over: today's counters start at zero, but everything
    // already recorded for previous days stays in history untouched —
    // that's the actual difference between "tracking" and "a checkbox
    // that resets and forgets."
    if (lastReset != todayKey) {
      await prefs.setString(_kLastResetDateKey, todayKey);
    }
    history.putIfAbsent(todayKey, () => {'water': 0, 'stretch': false});

    setState(() {
      _history = history;
      _waterCount = (history[todayKey]?['water'] as int?) ?? 0;
      _stretchDone = (history[todayKey]?['stretch'] as bool?) ?? false;
      _waterEnabled = prefs.getBool(_kWaterEnabledKey) ?? true;
      _stretchEnabled = prefs.getBool(_kStretchEnabledKey) ?? true;
      _stretchTime = TimeOfDay(
        hour: prefs.getInt(_kStretchHourKey) ?? 7,
        minute: prefs.getInt(_kStretchMinuteKey) ?? 30,
      );
    });
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep the stored history from growing forever — 60 days is plenty
    // for a "recent streak" feature while keeping the payload tiny.
    final keys = _history.keys.toList()..sort();
    if (keys.length > 60) {
      for (final k in keys.take(keys.length - 60)) {
        _history.remove(k);
      }
    }
    await prefs.setString(_kHistoryKey, jsonEncode(_history));
  }

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// Last [_historyDaysToShow] calendar days (oldest first, today last),
  /// each with whether water goal + stretch were both completed.
  List<_DayProgress> _recentDays() {
    final now = DateTime.now();
    return List.generate(_historyDaysToShow, (i) {
      final date = now.subtract(Duration(days: _historyDaysToShow - 1 - i));
      final key = _dateKey(date);
      final entry = _history[key];
      final water = (entry?['water'] as int?) ?? 0;
      final stretch = (entry?['stretch'] as bool?) ?? false;
      return _DayProgress(
        date: date,
        waterMet: water >= _dailyWaterGoal,
        stretchDone: stretch,
        isToday: key == _todayKey(),
      );
    });
  }

  /// Consecutive days, counting back from yesterday (today doesn't
  /// count until it's actually complete), where both the water goal and
  /// the stretch were done. This is the number shown next to the 🔥.
  int _currentStreak() {
    int streak = 0;
    var date = DateTime.now().subtract(const Duration(days: 1));
    while (true) {
      final entry = _history[_dateKey(date)];
      final water = (entry?['water'] as int?) ?? 0;
      final stretch = (entry?['stretch'] as bool?) ?? false;
      if (water >= _dailyWaterGoal && stretch) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    // Today also counts toward the visible streak once fully complete.
    final todayEntry = _history[_todayKey()];
    final todayWater = (todayEntry?['water'] as int?) ?? 0;
    final todayStretch = (todayEntry?['stretch'] as bool?) ?? false;
    if (todayWater >= _dailyWaterGoal && todayStretch) streak++;
    return streak;
  }

  Future<void> _incrementWater() async {
    if (_waterCount >= _dailyWaterGoal) return;
    setState(() {
      _waterCount++;
      _history[_todayKey()] = {'water': _waterCount, 'stretch': _stretchDone};
    });
    await _persistHistory();
  }

  Future<void> _toggleStretchDone() async {
    setState(() {
      _stretchDone = !_stretchDone;
      _history[_todayKey()] = {'water': _waterCount, 'stretch': _stretchDone};
    });
    await _persistHistory();
  }

  Future<void> _openSettingsSheet() async {
    final result = await showModalBottomSheet<_SaveResult>(
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

          bool exact = true;
          if (waterEnabled) {
            exact = await notifications.scheduleWaterReminders() && exact;
          } else {
            await notifications.cancelWaterReminders();
          }

          if (stretchEnabled) {
            exact = await notifications.scheduleStretchReminder(stretchTime) && exact;
          } else {
            await notifications.cancelStretchReminder();
          }

          return exact;
        },
      ),
    );

    if (!mounted || result == null) return;

    if (!result.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save reminders: ${result.errorMessage}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (!result.exact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Reminders saved, but exact timing isn't available — grant "
            '"Alarms & reminders" in system settings for on-the-dot '
            'timing. Reminders will still fire, just possibly a few '
            'minutes late.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders saved')),
      );
    }
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
    final days = _recentDays();
    final streak = _currentStreak();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "This week",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (streak > 0)
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak day${streak == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.mutedBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Weekly progress row — this is the actual "tracking" part.
            // Each day is a dot: filled teal when both water + stretch
            // were completed that day, half-filled when only one was,
            // outlined when neither was, and today gets a ring so it's
            // obviously "the one still in progress."
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((d) => _DayDot(day: d)).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              "Today",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
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

/// A single day's dot in the weekly progress row: filled teal when both
/// habits were completed that day, half-filled when only one was, and
/// outlined otherwise. Today gets a ring around it either way, so it
/// reads as "in progress" rather than "missed."
class _DayDot extends StatelessWidget {
  final _DayProgress day;
  const _DayDot({required this.day});

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final label = weekdayLabels[day.date.weekday - 1];

    Color fill;
    Color? border;
    if (day.fullyComplete) {
      fill = AppColors.calmTeal;
    } else if (day.partiallyComplete) {
      fill = AppColors.calmTealLight;
    } else {
      fill = AppColors.slate100;
    }
    if (day.isToday) border = AppColors.mutedBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: day.isToday ? AppColors.mutedBlue : AppColors.slate400,
            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 2) : null,
          ),
          child: day.fullyComplete
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ],
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
  final Future<bool> Function(bool water, bool stretch, TimeOfDay time)
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
  String? _errorText;

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

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });

    // THE ACTUAL FIX: previously nothing here was wrapped in try/catch,
    // so if scheduling threw (very possible — see notification_service's
    // comments), `_saving` never got reset and the sheet never closed,
    // which is exactly the "spinner runs forever" symptom. Now, whatever
    // happens, the finally block guarantees the button becomes usable
    // again and the person gets an honest result either way.
    bool exact = true;
    Object? error;
    try {
      exact = await widget.onSaved(_waterEnabled, _stretchEnabled, _stretchTime);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorText = error.toString());
      return; // stay open so the person can see the error and retry
    }

    Navigator.of(context).pop(_SaveResult(succeeded: true, exact: exact));
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
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
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

/// Result of a reminder-save attempt, returned from the settings sheet
/// so the parent screen (which has a stable, long-lived Scaffold
/// context) can show accurate feedback rather than the sheet trying to
/// show a SnackBar on a context that's mid-dismissal.
class _SaveResult {
  final bool succeeded;
  final bool exact;
  final String? errorMessage;
  const _SaveResult({
    required this.succeeded,
    this.exact = true,
    this.errorMessage,
  });
}

/// One day's worth of habit-tracker completion, used to render the
/// weekly progress row.
class _DayProgress {
  final DateTime date;
  final bool waterMet;
  final bool stretchDone;
  final bool isToday;
  const _DayProgress({
    required this.date,
    required this.waterMet,
    required this.stretchDone,
    required this.isToday,
  });

  bool get fullyComplete => waterMet && stretchDone;
  bool get partiallyComplete => waterMet || stretchDone;
}
