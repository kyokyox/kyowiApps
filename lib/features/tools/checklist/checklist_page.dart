import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import 'checklist_models.dart';
import 'checklist_service.dart';
import 'checklist_group_detail_page.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<ChecklistGroup> _groups = [];
  bool _loading = true;
  List<String> _justReset = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final groups = await ChecklistService.load();
    final resetNames = await ChecklistService.resetIfNeeded(groups);
    await ChecklistService.scheduleMidnightReminder();
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _justReset = resetNames;
      _loading = false;
    });
  }

  Future<void> _persist() => ChecklistService.save(_groups);

  void _addGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Grup Baru', style: TextStyle(color: AppColors.ink)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.ink),
          decoration: const InputDecoration(hintText: 'Misal: Rutinitas Pagi'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Buat')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _groups.add(ChecklistGroup(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, items: [])));
    _persist();
  }

  void _toggleActive(ChecklistGroup group) {
    setState(() {
      group.active = !group.active;
      if (group.active && group.lastResetDate == null) {
        // Pertama kali diaktifin -> set lastResetDate ke hari ini biar gak
        // langsung ke-reset lagi besoknya.
        final d = DateTime.now();
        group.lastResetDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
    });
    _persist();
  }

  void _openGroup(ChecklistGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChecklistGroupDetailPage(group: group, onChanged: _persist)),
    );
    setState(() {}); // refresh progress count pas balik
  }

  void _deleteGroup(ChecklistGroup group) {
    setState(() => _groups.remove(group));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.cyan,
        onPressed: _addGroup,
        child: const Icon(Icons.add, color: Color(0xFF1A120C)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                children: [
                  const SeraphHeader(
                      title: 'Check', accent: 'list', subtitle: 'Grup kegiatan, bisa aktifin lebih dari 1, reset tiap jam 12 malam'),
                  if (_justReset.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.1), border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(10)),
                      child: Text('✓ ${_justReset.join(', ')} baru aja direset buat hari ini.',
                          style: const TextStyle(color: AppColors.cyan, fontSize: 11.5)),
                    ),
                  ],
                  if (_groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(child: Text('Belum ada grup. Tap + buat bikin.', style: TextStyle(color: AppColors.gray, fontSize: 12))),
                    )
                  else
                    for (final group in _groups) _groupCard(group),
                ],
              ),
      ),
    );
  }

  Widget _groupCard(ChecklistGroup group) {
    final total = group.items.length;
    final done = group.doneCount;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: group.active ? AppColors.cyan.withValues(alpha: 0.5) : AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(total == 0 ? 'Belum ada kegiatan' : '$done/$total selesai', style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.magenta, size: 18), onPressed: () => _deleteGroup(group)),
              Switch(value: group.active, onChanged: (_) => _toggleActive(group), activeColor: AppColors.cyan),
            ],
          ),
        ),
      ),
    );
  }
}
