import 'package:flutter/material.dart';

/// Widget buat nampilin hasil eksekusi fitur (hash, response API, hasil
/// decode, dll) dengan gaya terminal Linux - header bar dengan 3 dot ala
/// macOS/Linux terminal, body item gelap pekat dengan teks monospace
/// hijau/cyan kayak console beneran.
class ConsoleOutput extends StatelessWidget {
  final String content;
  final String label;
  final Color textColor;
  final double fontSize;
  final double? maxHeight;
  final bool selectable;
  final bool showHeader;

  const ConsoleOutput({
    super.key,
    required this.content,
    this.label = 'output',
    this.textColor = const Color(0xFF6EE7A8), // hijau terminal klasik
    this.fontSize = 12,
    this.maxHeight,
    this.selectable = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: showHeader
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '\$ ',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700)),
            TextSpan(
                text: content,
                style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: fontSize, height: 1.5)),
          ]),
        ),
      ),
    );

    if (!showHeader) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2A2A))),
        clipBehavior: Clip.antiAlias,
        child: selectable ? SelectionArea(child: body) : body,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF161616),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
          selectable
              ? SelectionArea(child: body)
              : body,
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
