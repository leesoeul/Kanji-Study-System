class Verb {
  final int id;
  final String plainForm; // 기본형 (e.g., 食べる)
  final String reading; // 읽기 (e.g., たべる)
  final String meaning; // 뜻 (e.g., 먹다)
  final String hint;

  Verb({
    required this.id,
    required this.plainForm,
    required this.reading,
    required this.meaning,
    required this.hint,
  });
}
