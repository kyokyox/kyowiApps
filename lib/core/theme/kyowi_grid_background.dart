import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Background corak grid/kotak-kotak tipis - bagian dari redesign
/// "Warm Contrast". Dipasang 1x di root (main.dart), otomatis jadi
/// latar semua halaman tanpa perlu diulang-ulang di tiap file.
class KyowiGridBackground extends StatelessWidget {
  final Widget child;
  const KyowiGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: CustomPaint(
        painter: _GridPainter(),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  static const double _cell = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
