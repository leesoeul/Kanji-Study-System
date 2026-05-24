import 'package:flutter/material.dart';
import 'kanji_home_page.dart';
import 'verb_home_page.dart';
import 'login_screen.dart';

class StudyOptionsScreen extends StatelessWidget {
  final VoidCallback onThemeChanged;
  final StudyMode mode;

  const StudyOptionsScreen({
    super.key,
    required this.onThemeChanged,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final String title = (mode == StudyMode.kanji) ? '한자 외우기' : '동사 외우기';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로그인 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 60),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onThemeChanged: onThemeChanged,
                      mode: mode,
                    ),
                  ),
                );
              },
              child: const Text('로그인'),
            ),
            const SizedBox(height: 20),

            // 처음부터 시작하기 버튼
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 60),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                if (mode == StudyMode.kanji) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KanjiHomePage(
                        onThemeChanged: onThemeChanged,
                        startId: 1,
                        userId: null,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerbHomePage(
                        onThemeChanged: onThemeChanged,
                        startId: 1,
                        userId: null,
                      ),
                    ),
                  );
                }
              },
              child: const Text('처음부터 시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
