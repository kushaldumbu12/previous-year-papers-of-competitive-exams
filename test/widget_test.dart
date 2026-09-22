import 'package:flutter_test/flutter_test.dart';
import 'package:govt_exam_papers/main.dart';

void main() {
  testWidgets('App launches with splash screen and transitions to exam list', (WidgetTester tester) async {
    await tester.pumpWidget(const ExamPapersApp());
    expect(find.text('Exam Paper Collection'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Select Your Target Exam'), findsOneWidget);
  });
}
