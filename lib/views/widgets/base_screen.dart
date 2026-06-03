import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_localization_service.dart';
import '../../services/auth_service.dart';
import 'ai_helper_overlay.dart';

class BaseScreen extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final bool resizeToAvoidBottomInset;
  final bool showAiHelper;

  const BaseScreen({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.resizeToAvoidBottomInset = true,
    this.showAiHelper = true,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = provider.currentTheme == AppThemeType.defaultDark;
    
    final showAi = showAiHelper && authService.isLoggedIn;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      appBar: title != null
          ? AppBar(
              title: Text(
                title!,
                style: TextStyle(
                  color: provider.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: provider.textPrimaryColor),
              actions: actions,
            )
          : null,
      extendBodyBehindAppBar: true,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              provider.backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          // Background Overlay for readability
          Positioned.fill(
            child: Container(
              color: isDark 
                  ? Colors.black.withOpacity(0.4) 
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          // Body content
          SafeArea(
            child: body,
          ),
          // Floating AI helper overlay
          if (showAi)
            const AiHelperOverlay(),
        ],
      ),
    );
  }
}
