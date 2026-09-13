import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import 'calculator_engine.dart';

class ScientificCalculatorPage extends StatefulWidget {
  const ScientificCalculatorPage({super.key});

  @override
  State<ScientificCalculatorPage> createState() => _ScientificCalculatorPageState();
}

class _ScientificCalculatorPageState extends State<ScientificCalculatorPage> {
  String _expression = '';
  String _result = '0';
  String? _error;

  void _append(String s) {
    setState(() {
      _expression += s;
      _error = null;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = '0';
      _error = null;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() => _expression = _expression.substring(0, _expression.length - 1));
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      final value = CalculatorEngine.evaluate(_expression);
      setState(() {
        _result = value == value.roundToDouble() && value.abs() < 1e15
            ? value.toInt().toString()
            : value.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: SeraphHeader(
            title: 'Sci',
            accent: 'Calc',
            subtitle: _error ?? 'Kalkulator ilmiah - trig dalam derajat',
            padding: const EdgeInsets.only(bottom: 14),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(_expression.isEmpty ? ' ' : _expression,
                      style: const TextStyle(color: AppColors.gray, fontSize: 16)),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_result,
                      style: TextStyle(
                          color: _error != null ? AppColors.magenta : AppColors.ink,
                          fontSize: 40,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _row(['sin(', 'cos(', 'tan(', 'C']),
              _row(['log(', 'ln(', 'sqrt(', '⌫']),
              _row(['(', ')', '^', '/']),
              _row(['7', '8', '9', '*']),
              _row(['4', '5', '6', '-']),
              _row(['1', '2', '3', '+']),
              _row(['pi', '0', '.', '=']),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _row(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: keys.map((k) => Expanded(child: _key(k))).toList()),
    );
  }

  Widget _key(String label) {
    final isOperator = ['/', '*', '-', '+', '^'].contains(label);
    final isSpecial = ['C', '⌫', '='].contains(label);
    Color bg = AppColors.panel;
    Color fg = AppColors.ink;
    if (label == '=') {
      bg = AppColors.cyan;
      fg = const Color(0xFF1A120C);
    } else if (isOperator) {
      fg = AppColors.cyan;
    } else if (label == 'C') {
      fg = AppColors.magenta;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (label == 'C') {
              _clear();
            } else if (label == '⌫') {
              _backspace();
            } else if (label == '=') {
              _calculate();
            } else {
              _append(label);
            }
          },
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
            child: Text(label,
                style: TextStyle(
                    color: fg, fontSize: isSpecial ? 15 : 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
