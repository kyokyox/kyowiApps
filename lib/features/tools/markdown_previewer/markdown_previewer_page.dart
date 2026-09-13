import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class MarkdownPreviewerPage extends StatefulWidget {
  const MarkdownPreviewerPage({super.key});

  @override
  State<MarkdownPreviewerPage> createState() => _MarkdownPreviewerPageState();
}

class _MarkdownPreviewerPageState extends State<MarkdownPreviewerPage> {
  final _controller = TextEditingController(text: '''# Judul

Tulis **markdown** di sini, hasilnya langsung kerender di bawah.

- List item 1
- List item 2

> Kutipan contoh

`inline code` dan [link](https://kyowi.app)
''');
  bool _showPreviewOnly = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            children: [
              const SeraphHeader(
                  title: 'Markdown', accent: 'Previewer', subtitle: 'Tulis & preview markdown live',
                  padding: EdgeInsets.only(bottom: 14)),
              Row(
                children: [
                  Expanded(
                      child: _modeBtn('Split', !_showPreviewOnly, () => setState(() => _showPreviewOnly = false))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _modeBtn('Preview Aja', _showPreviewOnly, () => setState(() => _showPreviewOnly = true))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _showPreviewOnly
              ? _buildPreview()
              : Row(
                  children: [
                    Expanded(child: _buildEditor()),
                    Container(width: 1, color: AppColors.line),
                    Expanded(child: _buildPreview()),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
        decoration: const InputDecoration(hintText: 'Tulis markdown...'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Markdown(
        data: _controller.text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          h1: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w800),
          h2: const TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700),
          h3: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w700),
          code: const TextStyle(
              color: AppColors.cyan, backgroundColor: AppColors.bg, fontFamily: 'monospace', fontSize: 11.5),
          codeblockDecoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
          blockquote: const TextStyle(color: AppColors.gray, fontStyle: FontStyle.italic),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.cyan, width: 3)),
          ),
          listBullet: const TextStyle(color: AppColors.cyan),
          a: const TextStyle(color: AppColors.cyan, decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.panel2 : AppColors.panel,
          border: Border.all(color: active ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(color: active ? AppColors.ink : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
