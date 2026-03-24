import 'package:shared_preferences/shared_preferences.dart';

import 'theme_cubit.dart';

class ThemePreferences {
  static const _themeKey = 'app_theme_mode';

  Future<AppThemePreference> loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeKey);

    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }

  Future<void> saveThemePreference(AppThemePreference preference) async {
    final preferences = await SharedPreferences.getInstance();
    final value = switch (preference) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.system => 'system',
    };
    await preferences.setString(_themeKey, value);
  }
}
