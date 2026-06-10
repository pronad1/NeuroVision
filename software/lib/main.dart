// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/config/routes.dart';
import 'src/config/theme.dart';
import 'src/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase (for medical image storage)
  await Supabase.initialize(
    url: 'https://apfcycghfwiupflrpdgn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwZmN5Y2doZndpdXBmbHJwZGduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxOTM3ODMsImV4cCI6MjA3Mzc2OTc4M30.-bXtNLIizqYRoKwigPs21uRLcNwSI7Nj9w8ujaah_Gk',
  );

  runApp(const NeuroVisionApp());
}

class NeuroVisionApp extends StatelessWidget {
  const NeuroVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NVAuthProvider()),
      ],
      child: MaterialApp(
        title: 'NeuroVision AI',
        debugShowCheckedModeBanner: false,
        theme: NVTheme.darkTheme,
        initialRoute: Routes.splash,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
