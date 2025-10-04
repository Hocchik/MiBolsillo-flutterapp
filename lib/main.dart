import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // para recordar si hay sesión
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

import 'screens/add_transaction_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/account_screen.dart';
import 'screens/transaction_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool loggedIn = prefs.getBool('logged_in') ?? false;
  runApp(MyApp(initialRoute: loggedIn ? '/' : '/welcome'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

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
      },
    );
  }
}