class BookingStepsOfItem {
  final String bookingStep;
  final bool? isAttached;

  BookingStepsOfItem({
    required this.bookingStep,
    required this.isAttached,
  });

  factory BookingStepsOfItem.fromJson(Map<String, dynamic> json) {
    return BookingStepsOfItem(
      bookingStep: json['bookingStep'],
      isAttached: json['isAttached'],
    );
  }
}
