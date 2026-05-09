import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WearthApp());
}

class WearthApp extends StatelessWidget {
  const WearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wearth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
