import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view/welcome_view.dart';
import 'view/login_view.dart';
import 'view/register_view.dart';
import 'view/sales_dashboard_view.dart';
import 'view/sales_registration_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestDragonApp());
}

class TestDragonApp extends StatelessWidget {
  const TestDragonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestDragon',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeView(),
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/dashboardsales': (context) => const SalesDashboardView(),
          '/sales': (context) => const SalesRegistrationView(),
        }
    );
  }
}