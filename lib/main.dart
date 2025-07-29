import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/movie_provider.dart'; // Importación de MovieProvider
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Cargar el archivo .env
    print('TMDB_API_KEY cargada: ${dotenv.env['TMDB_API_KEY']}'); // Depuración
  } catch (e) {
    print('Error al cargar .env: $e'); // Depuración de errores
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => MovieProvider(),
      child: const CineTandemApp(),
    ),
  );
}

class CineTandemApp extends StatelessWidget {
  const CineTandemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineTandem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 31),
        primaryColor: const Color.fromARGB(255, 255, 60, 56),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(fontSize: 18, color: Colors.white70),
          titleSmall: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 10, 10, 31),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 60, 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}