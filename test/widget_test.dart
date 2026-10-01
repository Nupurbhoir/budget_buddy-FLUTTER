import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_buddy/main.dart';
import 'package:budget_buddy/providers/finance_provider.dart';
import 'package:budget_buddy/providers/theme_provider.dart';
import 'package:budget_buddy/services/storage_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('BudgetBuddy loads dashboard with financial balance', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
          ChangeNotifierProvider(create: (_) => FinanceProvider(storageService)),
        ],
        child: const BudgetBuddyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify key titles and balance elements appear
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Monthly Budget'), findsOneWidget);
  });
}
