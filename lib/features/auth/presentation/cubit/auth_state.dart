part of 'auth_cubit.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.isLoginMode = true,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final bool isLoginMode;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    bool? isSubmitting,
    bool? isLoginMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoginMode: isLoginMode ?? this.isLoginMode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isSubmitting,
    isLoginMode,
    errorMessage,
  ];
}
