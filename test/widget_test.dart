import 'package:flutter_test/flutter_test.dart';
import 'package:kyowi/main.dart';

void main() {
  testWidgets('KyowiApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const KyowiApp());
    // Cukup pastikan widget root ke-render tanpa exception,
    // gak perlu assert isi UI detail di sini.
    expect(find.byType(KyowiApp), findsOneWidget);
  });
}
