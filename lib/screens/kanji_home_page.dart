import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kanji_game/models/kanji.dart';
import 'package:kanji_game/data/kanji_data.dart';

class KanjiHomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final int startId;
  final String? userId;

  const KanjiHomePage({
    super.key,
    required this.onThemeChanged,
    required this.startId,
    this.userId,
  });

  @override
  State<KanjiHomePage> createState() => _KanjiHomePageState();
}

class _KanjiHomePageState extends State<KanjiHomePage> {
  int currentIndex = 0;
  bool _showAnswer = false;
  bool _showHint = false;
  bool _isRandomMode = false;
  late List<Kanji> kanjiDisplayList;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  bool _isHintLocked = false;
  bool _isAnswerLocked = false;
  // --- 더블 탭 감지를 위한 시간 기록 변수 추가 ---
  DateTime? _lastHintTapTime;
  DateTime? _lastAnswerTapTime;

  @override
  void initState() {
    super.initState();
    kanjiDisplayList = kanjiList;
    _textController = TextEditingController();
    _focusNode = FocusNode();
    currentIndex = kanjiList.indexWhere((kanji) => kanji.id == widget.startId);
    if (currentIndex == -1) {
      currentIndex = 0;
    }
    _updateTextController();
  }

  // --- 위젯이 사라질 때 리소스를 해제하기 위해 dispose 추가 ---
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveCurrentIndex() async {
    if (widget.userId != null) {
      final int currentKanjiId = kanjiDisplayList[currentIndex].id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId!)
          .set({'lastKanjiId': currentKanjiId});
    }
  }

  // --- 컨트롤러의 텍스트를 현재 한자 ID로 업데이트하는 함수 ---
  void _updateTextController() {
    _textController.text = kanjiDisplayList[currentIndex].id.toString();
  }

  void _showPreviousKanji() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      } else {
        currentIndex = kanjiDisplayList.length - 1;
      }
      // 고정 상태가 아닐 때만 숨김 처리
      if (!_isAnswerLocked) _showAnswer = false;
      if (!_isHintLocked) _showHint = false;

      _updateTextController();
    });
    _saveCurrentIndex();
  }

  void _showNextKanji() {
    setState(() {
      if (currentIndex < kanjiDisplayList.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
      if (!_isAnswerLocked) _showAnswer = false;
      if (!_isHintLocked) _showHint = false;

      _updateTextController();
    });
    _saveCurrentIndex();
  }

  void _revealAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _revealHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }

  void _toggleAnswerLock() {
    setState(() {
      _isAnswerLocked = !_isAnswerLocked;
      _showAnswer = _isAnswerLocked;
    });
  }

  void _toggleHintLock() {
    setState(() {
      _isHintLocked = !_isHintLocked;
      _showHint = _isHintLocked;
    });
  }

  void _toggleMode() {
    setState(() {
      _isRandomMode = !_isRandomMode;

      if (_isRandomMode) {
        kanjiDisplayList = List.from(kanjiList);
        kanjiDisplayList.shuffle();
        currentIndex = 0;
      } else {
        final Kanji currentKanjiOnScreen = kanjiDisplayList[currentIndex];
        kanjiDisplayList = kanjiList;
        currentIndex = kanjiList
            .indexWhere((kanji) => kanji.id == currentKanjiOnScreen.id);
      }
      _updateTextController();
    });
    _saveCurrentIndex();
  }

  // --- ID로 한자를 찾아 점프하는 새 함수 ---
  void _jumpToKanjiById(String text) {
    final int? targetId = int.tryParse(text);
    if (targetId == null) return;
    final int targetIndex =
        kanjiDisplayList.indexWhere((kanji) => kanji.id == targetId);
    if (targetIndex != -1) {
      setState(() {
        currentIndex = targetIndex;
        _showAnswer = false;
      });
    } else {
      _updateTextController();
    }
    _focusNode.unfocus();
    _saveCurrentIndex();
  }

  void _handleHintButtonPress() {
    final now = DateTime.now();
    if (_lastHintTapTime != null &&
        now.difference(_lastHintTapTime!) < const Duration(milliseconds: 300)) {
      _toggleHintLock();
    } else {
      if (!_isHintLocked) {
        _revealHint();
      }
    }
    _lastHintTapTime = now;
  }

  void _handleAnswerButtonPress() {
    final now = DateTime.now();
    if (_lastAnswerTapTime != null &&
        now.difference(_lastAnswerTapTime!) <
            const Duration(milliseconds: 300)) {
      _toggleAnswerLock();
    } else {
      if (!_isAnswerLocked) {
        _revealAnswer();
      }
    }
    _lastAnswerTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    final Kanji currentKanji = kanjiDisplayList[currentIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height; // AppBar 높이
    final topPadding = MediaQuery.of(context).padding.top; // 상태바 높이
    final contentMinHeight = screenHeight - appBarHeight - topPadding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('漢字を覚えよう！'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 기존의 화면 중앙 콘텐츠
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _showNextKanji();
              } else if (details.primaryVelocity! > 0) {
                _showPreviousKanji();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(minHeight: contentMinHeight),
                    padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              iconSize: 40,
                              onPressed: _showPreviousKanji,
                            ),
                            Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentKanji.character,
                                style: const TextStyle(fontSize: 120),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              iconSize: 40,
                              onPressed: _showNextKanji,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Visibility(
                          visible: _showAnswer,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Column(
                            children: [
                              Text(currentKanji.koreanName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode
                                        ? Colors.cyanAccent
                                        : const Color.fromARGB(255, 0, 0, 255),
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 10),
                              Text(
                                '훈독: ${currentKanji.kunyomi}  /  음독: ${currentKanji.onyomi}',
                                style: const TextStyle(fontSize: 22),
                              ),
                              // Text('음독: ${currentKanji.onyomi}',
                              //     style: const TextStyle(fontSize: 20)),
                              // const SizedBox(height: 10),
                              // Text('훈독: ${currentKanji.kunyomi}',
                              //     style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),

                        // --- 힌트 표시 부분 추가 ---
                        Visibility(
                          visible: _showHint,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 0.0),
                            child: Text(
                              '힌트: ${currentKanji.hint}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 힌트 버튼
                            IconButton(
                              icon: Icon(_isHintLocked
                                  ? Icons.lightbulb
                                  : Icons.lightbulb_outline),
                              color: _isHintLocked ? Colors.amber : null,
                              iconSize: 30,
                              onPressed: _handleHintButtonPress,
                            ),

                            const SizedBox(width: 20),
                            // 정답 버튼
                            ElevatedButton(
                              onPressed: _handleAnswerButtonPress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAnswerLocked
                                    ? (isDarkMode
                                        ? Colors.teal[700]
                                        : Colors.teal[100])
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 20),
                              ),
                              child: const Text('정답',
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 오른쪽 인덱스
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: const EdgeInsets.only(left: 20.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 20,
                            color: isDarkMode ? Colors.white : Colors.black),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _jumpToKanjiById,
                        onTap: () {
                          _textController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Text(
                      '/ ${kanjiList.length}',
                      style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      // --- 아이콘 색상 변경 ---
                      color: isDarkMode ? Colors.white : Colors.black,
                      onPressed: () {
                        _jumpToKanjiById(_textController.text);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 왼쪽 랜덤 토글 버튼
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  _isRandomMode ? Icons.sort : Icons.shuffle,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                iconSize: 30,
                onPressed: _toggleMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
