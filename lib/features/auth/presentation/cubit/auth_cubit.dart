import 'dart:async';

import 'package:coinly/features/auth/data/auth_repository.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(
        const AuthState(status: AuthStatus.checking),
      ) {
    _subscription = _authRepository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _subscription;

  void toggleMode() {
    emit(state.copyWith(isLoginMode: !state.isLoginMode, clearError: true));
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

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
    required String firstName,
    required String lastName,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        currencyCode: currencyCode,
        firstName: firstName,
        lastName: lastName,
      );
      emit(state.copyWith(isSubmitting: false));
    } on FirebaseAuthException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _mapError(error)));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await _authRepository.signInWithGoogle();
      emit(state.copyWith(isSubmitting: false));
    } on GoogleSignInException catch (error) {
      final message = _mapGoogleError(error);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: message,
          clearError: message == null,
        ),
      );
    } on FirebaseAuthException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _mapError(error)));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Google sign-in could not be completed.',
        ),
      );
    }
  }

  Future<void> completeProfile({required String currencyCode}) async {
    final user = state.user;
    if (user == null) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final updatedUser = await _authRepository.updateCurrencyCode(
        userId: user.id,
        currencyCode: currencyCode,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          user: updatedUser,
          clearError: true,
        ),
      );
    } on FirebaseAuthException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _mapError(error)));
    }
  }

  Future<void> signOut() {
    return _authRepository.signOut();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void _onAuthChanged(AppUser? user) {
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        clearError: true,
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
      case 'google-sign-in-failed':
        return 'Google sign-in could not be completed.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked with another sign-in method.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  String? _mapGoogleError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return null;
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in is currently unavailable on this device.';
      default:
        final description = error.description?.trim() ?? '';
        return description.isEmpty
            ? 'Google sign-in could not be completed.'
            : description;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}



