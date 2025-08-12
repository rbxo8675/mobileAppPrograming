import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/screens/home_screen.dart';

void main() {
  runApp(const CookTalkApp());
}

class CookTalkApp extends StatelessWidget {
  const CookTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'CookTalk',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Noto Sans KR', // 한글 폰트
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
