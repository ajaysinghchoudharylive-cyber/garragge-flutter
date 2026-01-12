class UserResponseData {
  final int? id;
  final String? username;
  final String? phone;
  final bool? isPremium;
  final String? validity;
  final String? subscriptionDate;
  final String? state;
  final String? role;

  UserResponseData({
    this.id,
    this.username,
    this.phone,
    this.isPremium,
    this.validity,
    this.subscriptionDate,
    this.state,
    this.role,
  });

  factory UserResponseData.fromJson(Map<String, dynamic> json) {
    return UserResponseData(
      id: json['id'],
      username: json['username'],
      phone: json['phone'],
      isPremium: json['is_premium'],
      validity: json['validity']?.toString(),
      subscriptionDate: json['subscription_date']?.toString(),
      state: json['state'],
      role: json['role'],
    );
  }
}

