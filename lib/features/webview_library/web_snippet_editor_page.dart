import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'web_snippet.dart';

class WebSnippetEditorPage extends StatefulWidget {
  final WebSnippet? existing; // null = mode buat baru, ada isinya = mode edit
  const WebSnippetEditorPage({super.key, this.existing});

  @override
  State<WebSnippetEditorPage> createState() => _WebSnippetEditorPageState();
}

class _WebSnippetEditorPageState extends State<WebSnippetEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _htmlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descController = TextEditingController(text: widget.existing?.desc ?? '');
    _htmlController = TextEditingController(
        text: widget.existing?.html ??
            '<!DOCTYPE html>\n<html>\n<head>\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<style>\n  body { background:#14100C; color:#F5EBE0; font-family:sans-serif; padding:20px; }\n</style>\n</head>\n<body>\n  <h1>Halo!</h1>\n</body>\n</html>');
  }

  void _save() {
    final title = _titleController.text.trim();
    final html = _htmlController.text;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul gak boleh kosong.')));
      return;
    }
    if (html.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code HTML gak boleh kosong.')));
      return;
    }

    final result = WebSnippet(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      desc: _descController.text.trim(),
      html: html,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Halaman' : 'Buat Halaman Baru',
            style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: AppColors.cyan), onPressed: _save),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('JUDUL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: const InputDecoration(hintText: 'Nama halaman...'),
            ),
            const SizedBox(height: 14),
            const Text('DESKRIPSI', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
              decoration: const InputDecoration(hintText: 'Deskripsi singkat (opsional)...'),
            ),
            const SizedBox(height: 14),
            const Text('CODE HTML', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _htmlController,
              maxLines: 16,
              style: const TextStyle(color: AppColors.ink, fontSize: 11.5, fontFamily: 'monospace'),
              decoration: const InputDecoration(hintText: '<html>...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('SIMPAN')),
          ],
        ),
      ),
    );
  }
}
