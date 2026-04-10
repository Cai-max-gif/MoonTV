import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:moontv/main.dart';
import 'package:moontv/services/theme_service.dart';

void main() {
  testWidgets('MoonTVApp should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MoonTVApp());
    // 验证应用能够正常构建，而不依赖于特定文本
    expect(tester.widget(find.byType(MoonTVApp)), isNotNull);
  });

  testWidgets('MoonTVApp should have ThemeService provider', (WidgetTester tester) async {
    await tester.pumpWidget(const MoonTVApp());
    // 验证ThemeService provider存在
    expect(find.byType(ChangeNotifierProvider<ThemeService>), findsOneWidget);
  });
}
