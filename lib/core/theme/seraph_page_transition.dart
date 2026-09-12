import 'package:flutter/material.dart';

/// Transisi halaman custom Kyowi: kombinasi rotasi tipis (bukan muter
/// 360 derajat norak), fade, dan scale - kesan "premium smooth", bukan
/// gimmick. Dipasang sekali di ThemeData, otomatis berlaku ke semua
/// Navigator.push() di seluruh app.
class SeraphPageTransitionsBuilder extends PageTransitionsBuilder {
  const SeraphPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        // Rotasi tipis: dari -6 derajat ke 0, cuma kerasa halus bukan "muter"
        final angle = (1 - value) * -0.05; // ~-3 derajat di awal
        final scale = 0.94 + (value * 0.06);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective tipis biar rotasi kerasa 3D bukan flat
              ..rotateY(angle)
              ..scale(scale),
            child: child,
          ),
        );
      },
    );
  }
}
