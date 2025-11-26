import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'navigation/auth_navigator.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notes_screen.dart';

Future main() async {
  // Load environment variables before running the app
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'Notes App',
        theme: ThemeData(primarySwatch: Colors.deepOrange),
        home: const AuthNavigator(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/notes': (context) => const NotesScreen(),
        },
      ),
    );
  }
}
