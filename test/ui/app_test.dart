import 'package:flutter_test/flutter_test.dart';

import 'package:kurs/main.dart';

void main() {
  testWidgets('app boots and shows the converter screen', (tester) async {
    await tester.pumpWidget(const KursApp());

    expect(find.text('Kurs'), findsOneWidget);
  });
}
