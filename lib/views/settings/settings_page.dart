import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('SettingsTitle'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Appearance Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: provider.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('Appearance'),
                        style: TextStyle(
                          color: provider.textPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),

                  // Theme Selection Dropdown/Tile
                  Text(
                    context.tr('Theme'),
                    style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AppThemeType>(
                    value: provider.currentTheme,
                    dropdownColor: provider.currentTheme == AppThemeType.defaultDark
                        ? const Color(0xFF262626)
                        : Colors.white,
                    style: TextStyle(color: provider.textPrimaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppThemeType.defaultDark,
                        child: Text(
                          'Futuristic Dark (Glassmorphic)',
                          style: TextStyle(color: provider.textPrimaryColor),
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppThemeType.classicLight,
                        child: Text(
                          'Workforce Light (Classic Red)',
                          style: TextStyle(color: provider.textPrimaryColor),
                        ),
                      ),
                    ],
                    onChanged: (AppThemeType? newTheme) {
                      if (newTheme != null) {
                        provider.setTheme(newTheme);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Language Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: provider.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('Language'),
                        style: TextStyle(
                          color: provider.textPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),

                  // Language Dropdown/Tile
                  Text(
                    context.tr('SelectLanguage'),
                    style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: provider.currentLanguage,
                    dropdownColor: provider.currentTheme == AppThemeType.defaultDark
                        ? const Color(0xFF262626)
                        : Colors.white,
                    style: TextStyle(color: provider.textPrimaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(
                          'English 🇬🇧',
                          style: TextStyle(color: provider.textPrimaryColor),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'sv',
                        child: Text(
                          'Svenska 🇸🇪',
                          style: TextStyle(color: provider.textPrimaryColor),
                        ),
                      ),
                    ],
                    onChanged: (String? newLang) {
                      if (newLang != null) {
                        provider.setLanguage(newLang);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
