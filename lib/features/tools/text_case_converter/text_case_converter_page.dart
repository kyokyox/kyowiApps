import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/theme/console_output.dart';

class TextCaseConverterPage extends StatefulWidget {
  const TextCaseConverterPage({super.key});

  @override
  State<TextCaseConverterPage> createState() => _TextCaseConverterPageState();
}

class _TextCaseConverterPageState extends State<TextCaseConverterPage> {
  final _controller = TextEditingController();
  String _result = '';

  List<String> get _words =>
      _controller.text.trim().split(RegExp(r'[\s_-]+')).where((w) => w.isNotEmpty).toList();

  void _convert(String Function(List<String>) transform) {
    setState(() => _result = transform(_words));
  }

  void _copy() {
    if (_result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Case', accent: 'Converter', subtitle: 'Ubah format huruf sekali klik'),
        TextField(
          controller: _controller,
          maxLines: 4,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Ketik atau paste teks...'),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _btn('UPPERCASE', () => _convert((w) => w.join(' ').toUpperCase())),
            _btn('lowercase', () => _convert((w) => w.join(' ').toLowerCase())),
            _btn('Title Case', () => _convert((w) => w.map(_capitalize).join(' '))),
            _btn('Sentence case', () => _convert((w) {
                  final s = w.join(' ').toLowerCase();
                  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
                })),
            _btn('camelCase', () => _convert((w) => w.isEmpty
                ? ''
                : w.first.toLowerCase() + w.skip(1).map(_capitalize).join())),
            _btn('PascalCase', () => _convert((w) => w.map(_capitalize).join())),
            _btn('snake_case', () => _convert((w) => w.map((s) => s.toLowerCase()).join('_'))),
            _btn('kebab-case', () => _convert((w) => w.map((s) => s.toLowerCase()).join('-'))),
          ],
        ),
        if (_result.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
              const Spacer(),
              GestureDetector(onTap: _copy, child: const Icon(Icons.copy, size: 14, color: AppColors.gray)),
            ],
          ),
          const SizedBox(height: 8),
          ConsoleOutput(content: _result, label: 'convert.sh'),
        ],
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _btn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
      child: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 11.5)),
    );
  }
}
