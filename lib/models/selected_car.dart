class SelectedCar {
  final String carImage;
  final String carName;
  final bool primary;

  SelectedCar({
    required this.carImage,
    required this.carName,
    required this.primary,
  });

  factory SelectedCar.fromJson(Map<String, dynamic> json) {
    return SelectedCar(
      carImage: json['carImage'] ?? '',
      carName: json['carName'] ?? '',
      primary: json['primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carImage': carImage,
      'carName': carName,
      'primary': primary,
    };
  }

  // Helper to extract brand from car name (assuming format like "Tata Nexon")
  String get brand {
    final parts = carName.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }
  
  // Helper to extract model from car name
  String get model {
    final parts = carName.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : carName;
  }
}