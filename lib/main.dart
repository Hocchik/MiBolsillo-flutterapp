import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // para recordar si hay sesión
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

import 'screens/add_transaction_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/statistics_screen_clean.dart';
import 'screens/account_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'services/repository.dart';
import 'services/currency_service.dart';
import 'screens/conflicts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize repository (local DB + sync manager)
  await Repository().init();
  // Initialize currency service (loads saved selection and tries to fetch rates)
  await CurrencyService().init();

  final prefs = await SharedPreferences.getInstance();
  final bool loggedIn = prefs.getBool('logged_in') ?? false;
  runApp(MyApp(initialRoute: loggedIn ? '/' : '/welcome'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuBolsillo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: initialRoute,
      routes: {
        '/welcome': (_) => WelcomeScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/': (_) => DashboardScreen(),
        '/add': (_) => AddTransactionScreen(),
        '/coach': (_) => CoachScreen(),
        '/goals': (_) => GoalsScreen(),
        '/statistics': (_) => StatisticsScreen(),
        '/account': (_) => AccountScreen(),
        '/transactions': (_) => TransactionListScreen(),
        '/conflicts': (_) => ConflictsScreen(),
      },
    );
  }
}