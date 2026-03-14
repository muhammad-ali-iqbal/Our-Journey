import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUPABASE CREDENTIALS
// Replace these with your actual values from:
// Supabase Dashboard → Project Settings → API
// ─────────────────────────────────────────────────────────────────────────────
const _supabaseUrl = 'https://feekhjymcmnhtmmqjuwd.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlZWtoanltY21uaHRtbXFqdXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MjkwMzQsImV4cCI6MjA4OTAwNTAzNH0.lPngObFOmd8NTFhlIlyP3smPFYrqC55mooeKoUk2HSE';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OurMapApp());
}

class OurMapApp extends StatelessWidget {
  const OurMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
