import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.currencyCode,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String email;
  final String currencyCode;
  final String firstName;
  final String lastName;

  bool get hasSelectedCurrency => currencyCode.trim().isNotEmpty;

  String get displayFirstName {
    if (firstName.trim().isNotEmpty) {
      return _normalizeName(firstName);
    }
    return 'there';
  }

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()]
        .where((part) => part.isNotEmpty)
        .map(_normalizeName)
        .toList(growable: false);

    return parts.join(' ');
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? currencyCode,
    String? firstName,
    String? lastName,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  String _normalizeName(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  @override
  List<Object> get props => [id, email, currencyCode, firstName, lastName];
}
