import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/theme/console_output.dart';

class DummyDataGeneratorPage extends StatefulWidget {
  const DummyDataGeneratorPage({super.key});

  @override
  State<DummyDataGeneratorPage> createState() => _DummyDataGeneratorPageState();
}

class _DummyDataGeneratorPageState extends State<DummyDataGeneratorPage> {
  static const _firstNames = [
    'Andi', 'Budi', 'Citra', 'Dewi', 'Eka', 'Fajar', 'Gita', 'Hendra', 'Indah', 'Joko',
    'Kartika', 'Lestari', 'Made', 'Nur', 'Oki', 'Putri', 'Rian', 'Siti', 'Tono', 'Umar'
  ];
  static const _lastNames = [
    'Saputra', 'Wijaya', 'Kusuma', 'Pratama', 'Santoso', 'Utami', 'Wibowo', 'Handoko', 'Susanto', 'Ramadhan'
  ];
  static const _domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'mail.com'];
  static const _streets = ['Jl. Merdeka', 'Jl. Sudirman', 'Jl. Diponegoro', 'Jl. Gatot Subroto', 'Jl. Ahmad Yani'];
  static const _cities = ['Jakarta', 'Surabaya', 'Bandung', 'Mojokerto', 'Yogyakarta', 'Semarang', 'Malang'];

  final _random = Random();
  int _count = 5;
  String _result = '';

  String _randomFrom(List<String> list) => list[_random.nextInt(list.length)];

  Map<String, dynamic> _generateOne(int index) {
    final first = _randomFrom(_firstNames);
    final last = _randomFrom(_lastNames);
    final username = '${first.toLowerCase()}${_random.nextInt(999)}';
    return {
      'id': index + 1,
      'name': '$first $last',
      'username': username,
      'email': '$username@${_randomFrom(_domains)}',
      'phone': '08${_random.nextInt(9)}${List.generate(8, (_) => _random.nextInt(10)).join()}',
      'address': {
        'street': '${_randomFrom(_streets)} No. ${_random.nextInt(200) + 1}',
        'city': _randomFrom(_cities),
      },
    };
  }

  void _generate() {
    final data = List.generate(_count, _generateOne);
    setState(() => _result = const JsonEncoder.withIndent('  ').convert(data));
  }

  void _copy() {
    if (_result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Dummy', accent: 'Data', subtitle: 'Generate data JSON palsu buat testing'),
        Row(
          children: [
            const Text('Jumlah:', style: TextStyle(color: AppColors.ink, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _count.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                activeColor: AppColors.cyan,
                inactiveColor: AppColors.line,
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.round()),
              ),
            ),
            Text('$_count', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
          ],
        ),
        ElevatedButton(onPressed: _generate, child: const Text('GENERATE ULANG')),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const Spacer(),
            GestureDetector(onTap: _copy, child: const Icon(Icons.copy, size: 14, color: AppColors.gray)),
          ],
        ),
        const SizedBox(height: 8),
        ConsoleOutput(content: _result, label: 'dummy.json', maxHeight: 400),
      ],
    );
  }
}
