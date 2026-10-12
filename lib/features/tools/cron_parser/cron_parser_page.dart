import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/theme/console_output.dart';
import 'cron_parser_engine.dart';

class CronParserPage extends StatefulWidget {
  const CronParserPage({super.key});

  @override
  State<CronParserPage> createState() => _CronParserPageState();
}

class _CronParserPageState extends State<CronParserPage> {
  final _controller = TextEditingController(text: '0 8 * * 1-5');
  String? _result;
  String? _error;

  static const _examples = [
    '0 8 * * 1-5',
    '*/15 * * * *',
    '0 0 1 * *',
    '30 2 * * 0',
  ];

  void _parse() {
    final expr = _controller.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _result = null;
        _error = null;
      });
      return;
    }
    try {
      setState(() {
        _result = CronParserEngine.describe(expr);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Cron', accent: 'Parser', subtitle: 'Jelasin jadwal cron expression'),
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppColors.cyan, fontSize: 15, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: '0 8 * * 1-5'),
          onChanged: (_) => _parse(),
        ),
        const SizedBox(height: 10),
        const Text('CONTOH', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((e) => GestureDetector(
                    onTap: () {
                      _controller.text = e;
                      _parse();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                      child: Text(e, style: const TextStyle(color: AppColors.ink, fontSize: 11, fontFamily: 'monospace')),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 18),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12))
        else if (_result != null) ...[
          const Text('ARTINYA', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          ConsoleOutput(content: _result!, label: 'cron.describe'),
        ],
      ],
    );
  }
}
