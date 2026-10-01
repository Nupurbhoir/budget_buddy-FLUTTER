import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/savings_challenge_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/responsive_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  // Initialize Firebase safely (supports both local/offline fallback and cloud Firebase)
  await FirebaseService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => FinanceProvider(storageService)),
      ],
      child: const BudgetBuddyApp(),
    ),
  );
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'BudgetBuddy - Take control of your money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MainNavigationShell(),
    );
  }
}

enum AppAuthState { splash, login, signup, authenticated }

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  AppAuthState _authState = AppAuthState.authenticated; // Start directly in app or splash
  int _currentTabIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Transactions',
    'Budgets',
    'Spending Analytics',
    'Profile & Settings',
    'Recurring Bills',
    'Savings Challenge',
    'Spending Categories',
    'Alerts & Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    // Auth Flow Transitions
    if (_authState == AppAuthState.splash) {
      return SplashScreen(
        onGetStarted: () => setState(() => _authState = AppAuthState.authenticated),
      );
    }

    if (_authState == AppAuthState.login) {
      return LoginScreen(
        onLoginSuccess: () => setState(() => _authState = AppAuthState.authenticated),
        onNavigateToSignup: () => setState(() => _authState = AppAuthState.signup),
      );
    }

    if (_authState == AppAuthState.signup) {
      return SignupScreen(
        onSignupSuccess: () => setState(() => _authState = AppAuthState.authenticated),
        onNavigateToLogin: () => setState(() => _authState = AppAuthState.login),
      );
    }

    // Authenticated Main App with ResponsiveScaffold
    Widget bodyContent;
    switch (_currentTabIndex) {
      case 0:
        bodyContent = DashboardScreen(onNavigateTab: (index) {
          setState(() => _currentTabIndex = index);
        });
        break;
      case 1:
        bodyContent = const TransactionsScreen();
        break;
      case 2:
        bodyContent = const BudgetsScreen();
        break;
      case 3:
        bodyContent = const AnalyticsScreen();
        break;
      case 4:
        bodyContent = ProfileScreen(
          onLogOut: () async {
            await FirebaseService().signOut();
            if (mounted) {
              setState(() => _authState = AppAuthState.login);
            }
          },
        );
        break;
      case 5:
        bodyContent = const BillsScreen();
        break;
      case 6:
        bodyContent = const SavingsChallengeScreen();
        break;
      case 7:
        bodyContent = const CategoriesScreen();
        break;
      case 8:
        bodyContent = const AlertsScreen();
        break;
      default:
        bodyContent = DashboardScreen(onNavigateTab: (index) {
          setState(() => _currentTabIndex = index);
        });
    }

    return ResponsiveScaffold(
      currentIndex: _currentTabIndex,
      title: _titles[_currentTabIndex.clamp(0, _titles.length - 1)],
      onNavigationChanged: (index) {
        setState(() => _currentTabIndex = index);
      },
      body: bodyContent,
    );
  }
}
