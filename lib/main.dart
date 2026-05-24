import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kanji_game/screens/start_screen.dart';

// Firebase 연동을 위한 main 함수 수정
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 여기에 Firebase 프로젝트의 웹 설정을 넣습니다.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDJiAuXgRopaCm84aCfv8JD6QjYHbU3ygg",
        authDomain: "kanji-game-55874.firebaseapp.com",
        projectId: "kanji-game-55874",
        storageBucket: "kanji-game-55874.appspot.com",
        messagingSenderId: "...",
        appId: "1:...:web:..."),
  );
  runApp(const KanjiApp());
}

class KanjiApp extends StatefulWidget {
  const KanjiApp({super.key});

  @override
  State<KanjiApp> createState() => _KanjiAppState();
}

class _KanjiAppState extends State<KanjiApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      // home: KanjiHomePage(onThemeChanged: _toggleTheme),
      home: StartScreen(onThemeChanged: _toggleTheme),
    );
  }
}
