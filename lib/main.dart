import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/word_service.dart';
import 'services/storage_service.dart';
import 'services/life_service.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Global tema notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i Başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Servisleri başlat
  await StorageService().init();
  await WordService().loadAllWords();
  await LifeService().init();

  // Kayıtlı temayı yükle
  final savedTheme = await StorageService().loadThemeMode();
  if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }

  runApp(const WearthApp());
}

class WearthApp extends StatelessWidget {
  const WearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Wearth',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
