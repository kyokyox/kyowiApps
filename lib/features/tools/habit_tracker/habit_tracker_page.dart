import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/local_json_list_store.dart';

class _Habit {
  String id;
  String name;
  List<String> completedDates; // format: 'yyyy-MM-dd'
  _Habit({required this.id, required this.name, required this.completedDates});

  factory _Habit.fromJson(Map<String, dynamic> j) => _Habit(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        completedDates: (j['completedDates'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'completedDates': completedDates};

  bool get doneToday => completedDates.contains(_todayKey());

  int get streak {
    var count = 0;
    var day = DateTime.now();
    while (completedDates.contains(_dateKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }
}

String _todayKey() => _dateKey(DateTime.now());
String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  static const _store = LocalJsonListStore('habits.json');
  final _inputController = TextEditingController();
  List<_Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await _store.load();
    setState(() {
      _habits = raw.map(_Habit.fromJson).toList();
      _loading = false;
    });
  }

  Future<void> _persist() => _store.save(_habits.map((h) => h.toJson()).toList());

  void _addHabit() {
    final name = _inputController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _habits.add(_Habit(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, completedDates: []));
      _inputController.clear();
    });
    _persist();
  }

  void _toggleToday(_Habit habit) {
    setState(() {
      final today = _todayKey();
      if (habit.completedDates.contains(today)) {
        habit.completedDates.remove(today);
      } else {
        habit.completedDates.add(today);
      }
    });
    _persist();
  }

  void _delete(_Habit habit) {
    setState(() => _habits.remove(habit));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Habit', accent: 'Tracker', subtitle: 'Checklist kebiasaan harian + streak'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: AppColors.ink, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Kebiasaan baru, misal: Olahraga...'),
                onSubmitted: (_) => _addHabit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _addHabit, icon: const Icon(Icons.add_circle, color: AppColors.cyan, size: 28)),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.cyan))
        else if (_habits.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('Belum ada kebiasaan.', style: TextStyle(color: AppColors.gray, fontSize: 12))),
          )
        else
          for (final habit in _habits) _habitCard(habit),
      ],
    );
  }

  Widget _habitCard(_Habit habit) {
    final streak = habit.streak;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleToday(habit),
            child: Icon(
              habit.doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
              color: habit.doneToday ? AppColors.cyan : AppColors.gray,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 13),
                    const SizedBox(width: 3),
                    Text('$streak hari beruntun', style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.magenta, size: 18), onPressed: () => _delete(habit)),
        ],
      ),
    );
  }
}
