import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/local_json_list_store.dart';

class _Todo {
  String id;
  String text;
  bool done;
  _Todo({required this.id, required this.text, required this.done});

  factory _Todo.fromJson(Map<String, dynamic> j) =>
      _Todo(id: j['id'] as String, text: j['text'] as String? ?? '', done: j['done'] as bool? ?? false);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  static const _store = LocalJsonListStore('todo.json');
  final _inputController = TextEditingController();
  List<_Todo> _todos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await _store.load();
    setState(() {
      _todos = raw.map(_Todo.fromJson).toList();
      _loading = false;
    });
  }

  Future<void> _persist() => _store.save(_todos.map((t) => t.toJson()).toList());

  void _add() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.add(_Todo(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, done: false));
      _inputController.clear();
    });
    _persist();
  }

  void _toggle(_Todo todo) {
    setState(() => todo.done = !todo.done);
    _persist();
  }

  void _delete(_Todo todo) {
    setState(() => _todos.remove(todo));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _todos.where((t) => !t.done).toList();
    final done = _todos.where((t) => t.done).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Todo', accent: 'List', subtitle: 'Checklist harian tersimpan lokal'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: AppColors.ink, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Tambah tugas baru...'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _add,
              icon: const Icon(Icons.add_circle, color: AppColors.cyan, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.cyan))
        else ...[
          if (pending.isEmpty && done.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                  child: Text('Belum ada tugas.', style: TextStyle(color: AppColors.gray, fontSize: 12))),
            ),
          for (final todo in pending) _todoTile(todo),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('SELESAI', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 6),
            for (final todo in done) _todoTile(todo),
          ],
        ],
      ],
    );
  }

  Widget _todoTile(_Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: GestureDetector(
          onTap: () => _toggle(todo),
          child: Icon(
            todo.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.done ? AppColors.cyan : AppColors.gray,
            size: 22,
          ),
        ),
        title: Text(
          todo.text,
          style: TextStyle(
            color: todo.done ? AppColors.gray : AppColors.ink,
            fontSize: 13,
            decoration: todo.done ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: AppColors.gray, size: 16),
          onPressed: () => _delete(todo),
        ),
      ),
    );
  }
}
