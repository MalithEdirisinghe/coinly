import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.currencyCode,
  });

  final String id;
  final String email;
  final String currencyCode;

  @override
  List<Object> get props => [id, email, currencyCode];
}
