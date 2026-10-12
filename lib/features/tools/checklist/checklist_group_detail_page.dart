import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'checklist_models.dart';

class ChecklistGroupDetailPage extends StatefulWidget {
  final ChecklistGroup group;
  final VoidCallback onChanged;
  const ChecklistGroupDetailPage({super.key, required this.group, required this.onChanged});

  @override
  State<ChecklistGroupDetailPage> createState() => _ChecklistGroupDetailPageState();
}

class _ChecklistGroupDetailPageState extends State<ChecklistGroupDetailPage> {
  final _inputController = TextEditingController();

  void _addItem() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.group.items.add(ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text));
      _inputController.clear();
    });
    widget.onChanged();
  }

  void _toggle(ChecklistItem item) {
    setState(() => item.done = !item.done);
    widget.onChanged();
  }

  void _deleteItem(ChecklistItem item) {
    setState(() => widget.group.items.remove(item));
    widget.onChanged();
  }

  void _renameGroup() async {
    final controller = TextEditingController(text: widget.group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Ganti Nama Grup', style: TextStyle(color: AppColors.ink)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.ink),
          decoration: const InputDecoration(hintText: 'Nama grup...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => widget.group.name = newName);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.group.items;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.gray, size: 18), onPressed: _renameGroup),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: AppColors.ink, fontSize: 13),
                      decoration: const InputDecoration(hintText: 'Tambah kegiatan...'),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _addItem, icon: const Icon(Icons.add_circle, color: AppColors.cyan, size: 28)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Belum ada kegiatan di grup ini.', style: TextStyle(color: AppColors.gray, fontSize: 12)))
                    : ListView(
                        children: [
                          for (final item in items) _itemTile(item),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: GestureDetector(
          onTap: () => _toggle(item),
          child: Icon(item.done ? Icons.check_circle : Icons.radio_button_unchecked, color: item.done ? AppColors.cyan : AppColors.gray, size: 22),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            color: item.done ? AppColors.gray : AppColors.ink,
            fontSize: 13,
            decoration: item.done ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(icon: const Icon(Icons.close, color: AppColors.gray, size: 16), onPressed: () => _deleteItem(item)),
      ),
    );
  }
}
