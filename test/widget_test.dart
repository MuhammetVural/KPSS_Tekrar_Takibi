import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_tekrar_takibi/main.dart';

void main() {
  testWidgets('App opens', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // TR varsayılan
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
  });
}