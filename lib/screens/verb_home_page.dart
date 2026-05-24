import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kanji_game/models/verb.dart';
import 'package:kanji_game/data/verb_data.dart';

class VerbHomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final int startId;
  final String? userId;

  const VerbHomePage({
    super.key,
    required this.onThemeChanged,
    required this.startId,
    this.userId,
  });

  @override
  State<VerbHomePage> createState() => _VerbHomePageState();
}

class _VerbHomePageState extends State<VerbHomePage> {
  int currentIndex = 0;
  bool _showAnswer = false;
  bool _showHint = false;
  bool _isRandomMode = false;
  late List<Verb> verbDisplayList;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isHintLocked = false;
  bool _isAnswerLocked = false;
  DateTime? _lastHintTapTime;
  DateTime? _lastAnswerTapTime;
  bool _showMeaningFirst = false;
  Map<String, String> _publicHints = {};

  @override
  void initState() {
    super.initState();
    verbDisplayList = verbList;
    _textController = TextEditingController();
    _focusNode = FocusNode();
    currentIndex = verbList.indexWhere((verb) => verb.id == widget.startId);
    if (currentIndex == -1) {
      currentIndex = 0;
    }
    _updateTextController();
    _loadPublicHint();
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
      final int currentVerbId = verbDisplayList[currentIndex].id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId!)
          .set({'lastVerbId': currentVerbId});
    }
  }

  // --- 컨트롤러의 텍스트를 현재 한자 ID로 업데이트하는 함수 ---
  void _updateTextController() {
    _textController.text = verbDisplayList[currentIndex].id.toString();
  }

  void _updateVerb() {
    _updateTextController();
    _loadPublicHint();
    _saveCurrentIndex();
  }

  void _showPreviousVerb() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      } else {
        currentIndex = verbDisplayList.length - 1;
      }
      if (!_isAnswerLocked) _showAnswer = false;
      if (!_isHintLocked) _showHint = false;
    });
    _updateVerb();
  }

  void _showNextVerb() {
    setState(() {
      if (currentIndex < verbDisplayList.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
      if (!_isAnswerLocked) _showAnswer = false;
      if (!_isHintLocked) _showHint = false;
    });
    _updateVerb();
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
        verbDisplayList = List.from(verbList);
        verbDisplayList.shuffle();
        currentIndex = 0;
      } else {
        final Verb currentVerbOnScreen = verbDisplayList[currentIndex];
        verbDisplayList = verbList;
        currentIndex =
            verbList.indexWhere((verb) => verb.id == currentVerbOnScreen.id);
      }
      _updateTextController();
    });
    _saveCurrentIndex();
  }

  // --- ID로 한자를 찾아 점프하는 새 함수 ---
  void _jumpToVerbById(String text) {
    final int? targetId = int.tryParse(text);
    if (targetId == null) {
      _updateTextController();
      _focusNode.unfocus();
      return;
    }

    final int targetIndex =
        verbDisplayList.indexWhere((verb) => verb.id == targetId);

    if (targetIndex != -1) {
      setState(() {
        currentIndex = targetIndex;
        if (!_isAnswerLocked) _showAnswer = false;
        if (!_isHintLocked) _showHint = false;
      });
      _updateVerb();
    } else {
      _updateTextController();
    }
    _focusNode.unfocus();
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

  void _toggleDisplayMode() {
    setState(() {
      _showMeaningFirst = !_showMeaningFirst;
      _showAnswer = false;
      _showHint = false;
      _isAnswerLocked = false;
      _isHintLocked = false;
    });
  }

  Future<void> _loadPublicHint() async {
    final verbId = verbDisplayList[currentIndex].id.toString();
    final docRef =
        FirebaseFirestore.instance.collection('publicVerbHints').doc(verbId);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      setState(() {
        _publicHints[verbId] = docSnap.data()?['hintText'];
      });
    } else {
      setState(() {
        _publicHints[verbId] = '';
      });
    }
  }

  void _editPublicHint() {
    final verbId = verbDisplayList[currentIndex].id.toString();
    final hintEditController =
        TextEditingController(text: _publicHints[verbId] ?? '');

    showDialog(
      context: context,
      // barrierDismissible: false, // 팝업 바깥을 눌러도 닫히지 않게 하려면 주석 해제
      builder: (context) {
        // --- 이 부분이 완전히 새로운 커스텀 팝업으로 변경되었습니다 ---
        return Scaffold(
          // 1. 키보드가 올라와도 화면 크기가 변하지 않도록 설정 (핵심)
          resizeToAvoidBottomInset: false,
          // 2. 뒷배경을 반투명하게 만들어 팝업처럼 보이게 함
          backgroundColor: Colors.black.withOpacity(0.5),
          body: Center(
            // 3. 팝업을 화면 중앙에 위치시킴
            child: Card(
              // 4. Card 위젯으로 팝업의 모양을 만듦
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 내용만큼만 높이를 차지
                  children: [
                    const Text(
                      '공용 힌트 수정',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hintEditController,
                      autofocus: true,
                      decoration:
                          const InputDecoration(hintText: '모두가 볼 힌트를 입력하세요...'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newHint = hintEditController.text;
                            await FirebaseFirestore.instance
                                .collection('publicVerbHints')
                                .doc(verbId)
                                .set({'hintText': newHint});

                            setState(() {
                              _publicHints[verbId] = newHint;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('저장'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Verb currentVerb = verbDisplayList[currentIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final contentMinHeight = screenHeight - appBarHeight - topPadding;
    final verbId = currentVerb.id.toString();
    final String displayHint = (_publicHints[verbId]?.isNotEmpty ?? false)
        ? _publicHints[verbId]!
        : currentVerb.hint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('動詞を覚えよう！'),
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
                _showNextVerb();
              } else if (details.primaryVelocity! > 0) {
                _showPreviousVerb();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(minHeight: contentMinHeight),
                    padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                iconSize: 40,
                                onPressed: _showPreviousVerb,
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _showMeaningFirst
                                          ? currentVerb.meaning
                                              .replaceAll(',', '\n')
                                          : currentVerb.plainForm,
                                      style: const TextStyle(fontSize: 50),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                iconSize: 40,
                                onPressed: _showNextVerb,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Visibility(
                          visible: _showAnswer,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Column(
                            children: [
                              // 뜻 먼저 보기 모드일 때
                              if (_showMeaningFirst) ...[
                                Text(
                                  '기본형: ${currentVerb.plainForm}',
                                  style: TextStyle(
                                      fontSize: 22,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text('읽기: ${currentVerb.reading}',
                                    style: const TextStyle(fontSize: 22)),
                              ] else ...[
                                Text('읽기: ${currentVerb.reading}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: isDarkMode
                                          ? Colors.cyanAccent
                                          : const Color.fromARGB(
                                              255, 0, 0, 255),
                                      fontWeight: FontWeight.bold,
                                    )),
                                const SizedBox(height: 10),
                                Text('뜻: ${currentVerb.meaning}',
                                    style: const TextStyle(fontSize: 20)),
                              ]
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    '힌트: $displayHint',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                  ),
                                ), // 힌트 수정 버튼을 항상 보이도록 변경
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  iconSize: 20,
                                  onPressed: _editPublicHint,
                                ),
                              ],
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
                        onSubmitted: _jumpToVerbById,
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
                      '/ ${verbList.length}',
                      style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      // --- 아이콘 색상 변경 ---
                      color: isDarkMode ? Colors.white : Colors.black,
                      onPressed: () {
                        _jumpToVerbById(_textController.text);
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
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isRandomMode ? Icons.sort : Icons.shuffle,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    iconSize: 30,
                    onPressed: _toggleMode,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.swap_horiz,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    iconSize: 30,
                    onPressed: _toggleDisplayMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
