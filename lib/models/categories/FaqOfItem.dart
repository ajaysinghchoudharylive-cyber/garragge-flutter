class FaqOfItem {
  final String question;
  final String answer;
  final bool? isAttached;
  bool isExpanded;

  FaqOfItem({
    required this.question,
    required this.answer,
    required this.isAttached,
    required this.isExpanded,
  });

  factory FaqOfItem.fromJson(Map<String, dynamic> json) {
    return FaqOfItem(
      question: json['question'],
      answer: json['answer'],
      isAttached: json['isAttached'],
      isExpanded: json['isExpanded'] ?? false,
    );
  }
}
