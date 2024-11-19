import 'package:flutter/material.dart';
import 'screens/user_login.dart';
import 'screens/user_registration.dart';
import 'screens/bingo_play.dart';
import 'screens/transaction.dart';
import 'package:provider/provider.dart';
import 'controller/bingo_controller.dart';
void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BingoController()),
    ],
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bingo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/bingo': (context) => const BingoCardScreen(),
      },
    );
  }
}
