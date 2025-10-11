import 'package:cooktalk/providers/app_settings_provider.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/providers/favorites_provider.dart';
import 'package:cooktalk/screens/home_screen.dart';
import 'package:cooktalk/screens/youtube_analyze_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Make Firebase optional for MVP/offline runs
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {
    // Ignore Firebase init/auth errors in offline/dev
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
      ],
      child: MaterialApp(
        title: 'CookTalk',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        routes: {
          '/yt-analyze': (_) => const YoutubeAnalyzeScreen(),
        },
      ),
    );
  }
}
