import 'package:admin_pool_web/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a tela de acesso do Admin Pool', (tester) async {
    await tester.pumpWidget(const AdminPoolApp());

    expect(find.text('Admin Pool'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
