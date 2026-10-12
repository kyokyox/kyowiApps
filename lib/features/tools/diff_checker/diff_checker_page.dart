import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

enum _LineType { same, added, removed }

class _DiffLine {
  final String text;
  final _LineType type;
  _DiffLine(this.text, this.type);
}

class DiffCheckerPage extends StatefulWidget {
  const DiffCheckerPage({super.key});

  @override
  State<DiffCheckerPage> createState() => _DiffCheckerPageState();
}

class _DiffCheckerPageState extends State<DiffCheckerPage> {
  final _leftController = TextEditingController();
  final _rightController = TextEditingController();
  List<_DiffLine>? _result;

  void _compare() {
    final linesA = _leftController.text.split('\n');
    final linesB = _rightController.text.split('\n');
    setState(() => _result = _diffLines(linesA, linesB));
  }

  /// Algoritma LCS (Longest Common Subsequence) sederhana buat cari baris
  /// yang sama & beda antara 2 teks - pure Dart, dasar dari `git diff`.
  List<_DiffLine> _diffLines(List<String> a, List<String> b) {
    final n = a.length, m = b.length;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = a[i] == b[j] ? dp[i + 1][j + 1] + 1 : (dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    final result = <_DiffLine>[];
    var i = 0, j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        result.add(_DiffLine(a[i], _LineType.same));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        result.add(_DiffLine(a[i], _LineType.removed));
        i++;
      } else {
        result.add(_DiffLine(b[j], _LineType.added));
        j++;
      }
    }
    while (i < n) {
      result.add(_DiffLine(a[i], _LineType.removed));
      i++;
    }
    while (j < m) {
      result.add(_DiffLine(b[j], _LineType.added));
      j++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Diff', accent: 'Checker', subtitle: 'Bandingin 2 teks, liat apa yang beda'),
        const Text('TEKS ASLI', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _leftController,
          maxLines: 5,
          style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'Teks versi lama...'),
        ),
        const SizedBox(height: 12),
        const Text('TEKS BARU', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _rightController,
          maxLines: 5,
          style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'Teks versi baru...'),
        ),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: _compare, child: const Text('BANDINGIN')),
        if (_result != null) ...[
          const SizedBox(height: 18),
          const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border.all(color: const Color(0xFF2A2A2A)), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _result!.map(_lineWidget).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(Colors.greenAccent, 'Ditambah'),
              const SizedBox(width: 14),
              _legend(AppColors.magenta, 'Dihapus'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _lineWidget(_DiffLine line) {
    Color bg;
    Color fg;
    String prefix;
    switch (line.type) {
      case _LineType.added:
        bg = Colors.greenAccent.withValues(alpha: 0.1);
        fg = Colors.greenAccent;
        prefix = '+ ';
        break;
      case _LineType.removed:
        bg = AppColors.magenta.withValues(alpha: 0.1);
        fg = AppColors.magenta;
        prefix = '- ';
        break;
      case _LineType.same:
        bg = Colors.transparent;
        fg = const Color(0xFF8A8F98);
        prefix = '  ';
    }
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$prefix${line.text}', style: TextStyle(color: fg, fontFamily: 'monospace', fontSize: 11.5)),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
      ],
    );
  }
}
