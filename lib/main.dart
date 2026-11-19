import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart'; // 👈 Import the new theme
import 'screens/animated_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DsjvApp());
}

class DsjvApp extends StatelessWidget {
  const DsjvApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConfig.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.themeData, // 👈 Apply the theme here
    home: const AnimatedSplashScreen(),
  );
}