import 'dart:async';

import 'package:coinly/features/auth/data/auth_repository.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(
        AuthState(
          status: authRepository.currentUser == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: authRepository.currentUser,
        ),
      ) {
    _subscription = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _subscription;

  void toggleMode() {
    emit(state.copyWith(isLoginMode: !state.isLoginMode, errorMessage: null));
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      await _authRepository.signIn(email: email, password: password);
      emit(state.copyWith(isSubmitting: false));
    } on FirebaseAuthException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _mapError(error)));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String currencyCode,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        currencyCode: currencyCode,
      );
      emit(state.copyWith(isSubmitting: false));
    } on FirebaseAuthException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _mapError(error)));
    }
  }

  Future<void> signOut() {
    return _authRepository.signOut();
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void _onAuthChanged(AppUser? user) {
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ),
    );
  }

  String _mapError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
