import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_preferences.dart';

enum AppThemePreference { system, light, dark }

class ThemeState extends Equatable {
  const ThemeState({required this.preference, this.isLoaded = false});

  final AppThemePreference preference;
  final bool isLoaded;

  ThemeMode get themeMode {
    switch (preference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  ThemeState copyWith({
    AppThemePreference? preference,
    bool? isLoaded,
  }) {
    return ThemeState(
      preference: preference ?? this.preference,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object> get props => [preference, isLoaded];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required ThemePreferences preferences})
    : _preferences = preferences,
      super(
        const ThemeState(
          preference: AppThemePreference.system,
          isLoaded: false,
        ),
      );

  final ThemePreferences _preferences;

  Future<void> loadTheme() async {
    final preference = await _preferences.loadThemePreference();
    emit(ThemeState(preference: preference, isLoaded: true));
  }

  Future<void> setTheme(AppThemePreference preference) async {
    await _preferences.saveThemePreference(preference);
    emit(ThemeState(preference: preference, isLoaded: true));
  }
}
