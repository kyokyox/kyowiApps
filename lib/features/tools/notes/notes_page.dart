import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/local_json_list_store.dart';

class _Note {
  String id;
  String title;
  String content;
  int updatedAt;
  _Note({required this.id, required this.title, required this.content, required this.updatedAt});

  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        updatedAt: j['updatedAt'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'content': content, 'updatedAt': updatedAt};
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const _store = LocalJsonListStore('notes.json');
  List<_Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await _store.load();
    setState(() {
      _notes = raw.map(_Note.fromJson).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _store.save(_notes.map((n) => n.toJson()).toList());
  }

  void _openEditor({_Note? note}) async {
    final isNew = note == null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'Catatan Baru' : 'Edit Catatan',
              style: const TextStyle(fontSize: 14, color: AppColors.ink)),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.cyan),
              onPressed: () {
                if (titleController.text.trim().isEmpty && contentController.text.trim().isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  if (isNew) {
                    _notes.insert(
                      0,
                      _Note(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        content: contentController.text,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                  } else {
                    note.title = titleController.text.trim();
                    note.content = contentController.text;
                    note.updatedAt = DateTime.now().millisecondsSinceEpoch;
                    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  }
                });
                _persist();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                      color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(hintText: 'Judul...', border: InputBorder.none),
                ),
                const Divider(color: AppColors.line),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
                    decoration:
                        const InputDecoration(hintText: 'Tulis catatan...', border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  void _delete(_Note note) {
    setState(() => _notes.remove(note));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.cyan,
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, color: Color(0xFF1A120C)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                children: [
                  const SeraphHeader(title: 'Notes', subtitle: 'Catatan cepat tersimpan lokal'),
                  if (_notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                          child: Text('Belum ada catatan. Tap + buat mulai.',
                              style: TextStyle(color: AppColors.gray, fontSize: 12))),
                    )
                  else
                    for (final note in _notes) _noteCard(note),
                ],
              ),
      ),
    );
  }

  Widget _noteCard(_Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _openEditor(note: note),
        title: Text(note.title.isEmpty ? '(Tanpa judul)' : note.title,
            style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(note.content.replaceAll('\n', ' '),
            style: const TextStyle(color: AppColors.gray, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.magenta, size: 18),
          onPressed: () => _delete(note),
        ),
      ),
    );
  }
}
