class TermsOfItem {
  final String heading;
  final String term;
  final bool? isAttached;

  TermsOfItem({
    required this.heading,
    required this.term,
    required this.isAttached,
  });

  factory TermsOfItem.fromJson(Map<String, dynamic> json) {
    return TermsOfItem(
      heading: json['heading'],
      term: json['term'],
      isAttached: json['isAttached'],
    );
  }
}
