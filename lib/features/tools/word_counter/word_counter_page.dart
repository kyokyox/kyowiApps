import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class WordCounterPage extends StatefulWidget {
  const WordCounterPage({super.key});

  @override
  State<WordCounterPage> createState() => _WordCounterPageState();
}

class _WordCounterPageState extends State<WordCounterPage> {
  final _controller = TextEditingController();
  int _chars = 0;
  int _charsNoSpace = 0;
  int _words = 0;
  int _sentences = 0;
  int _paragraphs = 0;

  void _recalculate() {
    final text = _controller.text;
    setState(() {
      _chars = text.length;
      _charsNoSpace = text.replaceAll(RegExp(r'\s'), '').length;
      _words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      _sentences = text.trim().isEmpty ? 0 : RegExp(r'[.!?]+').allMatches(text).length;
      _paragraphs = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Word', accent: 'Counter', subtitle: 'Hitung kata, karakter, kalimat, paragraf'),
        TextField(
          controller: _controller,
          maxLines: 8,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Paste atau ketik teks di sini...'),
          onChanged: (_) => _recalculate(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('Kata', _words)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Karakter', _chars)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Tanpa Spasi', _charsNoSpace)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Kalimat', _sentences)),
          ],
        ),
        const SizedBox(height: 10),
        _statCard('Paragraf', _paragraphs),
      ],
    );
  }

  Widget _statCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: const TextStyle(color: AppColors.cyan, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
        ],
      ),
    );
  }
}
