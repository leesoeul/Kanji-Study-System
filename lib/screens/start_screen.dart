import 'package:flutter/material.dart';
import 'package:kanji_game/screens/admin_screen.dart';
import 'login_screen.dart';
import 'study_options_screen.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onThemeChanged;
  const StartScreen({super.key, required this.onThemeChanged});

// --- 관리자 로그인 다이얼로그를 보여주는 함수 ---
  void _showAdminLoginDialog(BuildContext context) {
    final TextEditingController adminPasswordController =
        TextEditingController();
    const String adminPassword = '1128'; // 관리자 비밀번호

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('관리자 로그인'),
          content: TextField(
            controller: adminPasswordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: '관리자 비밀번호',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (adminPasswordController.text == adminPassword) {
                  Navigator.pop(context);
                  Navigator.push(
                    // 관리자 페이지로 이동
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminScreen(),
                    ),
                  );
                } else {
                  print('관리자 비밀번호 틀림');
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => _showAdminLoginDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: onThemeChanged,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 한자 외우기 버튼
            ElevatedButton.icon(
              icon: const Icon(Icons.font_download_outlined),
              label: const Text('한자 외우기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 60),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudyOptionsScreen(
                          onThemeChanged: onThemeChanged,
                          mode: StudyMode.kanji),
                    ));
              },
            ),
            const SizedBox(height: 20),

            // 동사 외우기 버튼
            ElevatedButton.icon(
              icon: const Icon(Icons.translate),
              label: const Text('동사 외우기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 60),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudyOptionsScreen(
                          onThemeChanged: onThemeChanged, mode: StudyMode.verb),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
