/// Represents the current logged-in user profile and preferences.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String currency;
  final double monthlyBudget;
  final bool enableNotifications;
  final bool biometricAuth;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.currency = '\$',
    this.monthlyBudget = 3000.00,
    this.enableNotifications = true,
    this.biometricAuth = false,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? currency,
    double? monthlyBudget,
    bool? enableNotifications,
    bool? biometricAuth,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      biometricAuth: biometricAuth ?? this.biometricAuth,
    );
  }
}
