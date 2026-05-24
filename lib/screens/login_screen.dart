// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kanji_home_page.dart';
import 'verb_home_page.dart'; // 동사 페이지 import

enum StudyMode { kanji, verb }

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final StudyMode mode;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.mode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final String userId = _passwordController.text;

    // 4자리 숫자인지 확인
    if (userId.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 4자리를 입력해주세요.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final docSnap = await docRef.get();

    if (widget.mode == StudyMode.kanji) {
      int lastKanjiId = 1;
      if (docSnap.exists) {
        lastKanjiId = docSnap.data()?['lastKanjiId'] ?? 1;
      } else {
        await docRef.set({'lastKanjiId': 1});
      }
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => KanjiHomePage(
                onThemeChanged: widget.onThemeChanged,
                startId: lastKanjiId,
                userId: userId),
          ));
    } else {
      // StudyMode.verb
      int lastVerbId = 1;
      if (docSnap.exists) {
        lastVerbId = docSnap.data()?['lastVerbId'] ?? 1;
      } else {
        await docRef.set({'lastVerbId': 1}, SetOptions(merge: true));
      }
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerbHomePage(
                onThemeChanged: widget.onThemeChanged,
                startId: lastVerbId,
                userId: userId),
          ));
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8.0),
                decoration: const InputDecoration(
                  labelText: '비밀번호 4자리',
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _login,
                child: const Text('입력'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
