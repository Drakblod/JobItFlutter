import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'translations.dart';

enum AppThemeType {
  defaultDark, // Futuristic Glassmorphism Dark
  classicLight, // Workforce Classic Red/White Light
}

class ThemeAndLocalizationProvider extends ChangeNotifier {
  static const String _languageKey = 'SelectedLanguage';
  static const String _themeKey = 'SelectedTheme';

  String _currentLanguage = 'en';
  AppThemeType _currentTheme = AppThemeType.defaultDark;
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  AppThemeType get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;

  ThemeAndLocalizationProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    
    final themeInt = prefs.getInt(_themeKey) ?? 0;
    _currentTheme = themeInt == 1 ? AppThemeType.classicLight : AppThemeType.defaultDark;
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'sv') return;
    _currentLanguage = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<void> setTheme(AppThemeType themeType) async {
    _currentTheme = themeType;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeType == AppThemeType.classicLight ? 1 : 0);
  }

  // Translation lookups with optional formatting (e.g. ActiveJobs: "{0} Active Jobs")
  String translate(String key, [List<dynamic>? args]) {
    final langMap = appTranslations[_currentLanguage] ?? appTranslations['en']!;
    String val = langMap[key] ?? key;
    
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        val = val.replaceAll('{$i}', args[i].toString());
      }
    }
    return val;
  }

  // Custom Colors
  Color get primaryColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFFD32F2F) 
      : const Color(0xFF6366F1);

  Color get primaryDarkColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFFB71C1C) 
      : const Color(0xFF4F46E5);

  Color get secondaryColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFF424242) 
      : const Color(0xFF67E8F9);

  Color get tertiaryColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFF757575) 
      : const Color(0xFF10B981);

  Color get backgroundColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFFF5F5F5) 
      : const Color(0xFF1A1A1A);

  Color get surfaceColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFFFFFFFF) 
      : const Color(0x1AFFFFFF); // 10% Opacity White for Glass

  Color get borderColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFFE0E0E0) 
      : const Color(0x33FFFFFF); // 20% Opacity White for Glass Border

  Color get textPrimaryColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFF212121) 
      : const Color(0xFFFFFFFF);

  Color get textSecondaryColor => _currentTheme == AppThemeType.classicLight 
      ? const Color(0xFF757575) 
      : const Color(0xFFA3A3A3);

  String get backgroundImage {
    return _currentTheme == AppThemeType.classicLight 
        ? 'assets/images/background2_red.webp' 
        : 'assets/images/soliddarkbg.jpg';
  }

  ThemeData get themeData {
    final isDark = _currentTheme == AppThemeType.defaultDark;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Urbanist',
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 12),
      ),
    );
  }
}

extension BuildContextExtension on BuildContext {
  String tr(String key, [List<dynamic>? args]) {
    return Provider.of<ThemeAndLocalizationProvider>(this, listen: false).translate(key, args);
  }

  ThemeAndLocalizationProvider get themeProvider {
    return Provider.of<ThemeAndLocalizationProvider>(this, listen: false);
  }
}
