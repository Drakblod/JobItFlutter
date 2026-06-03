import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('AboutTitle'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & App Info Banner
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: provider.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: provider.primaryColor.withOpacity(0.3), width: 2),
                      ),
                      child: Icon(
                        Icons.construction,
                        size: 64,
                        color: provider.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('AppTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 2.0 (Flutter Edition)',
                      style: TextStyle(
                        color: provider.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('DevelopedBy'),
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // How It Works Timeline section
              Text(
                context.tr('HowItWorks'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildStepCard(
                stepNum: '1',
                text: context.tr('HowItWorksStep1'),
                icon: Icons.create_new_folder,
                provider: provider,
              ),
              const SizedBox(height: 8),
              _buildStepCard(
                stepNum: '2',
                text: context.tr('HowItWorksStep2'),
                icon: Icons.group_add,
                provider: provider,
              ),
              const SizedBox(height: 8),
              _buildStepCard(
                stepNum: '3',
                text: context.tr('HowItWorksStep3'),
                icon: Icons.forum,
                provider: provider,
              ),
              const SizedBox(height: 8),
              _buildStepCard(
                stepNum: '4',
                text: context.tr('HowItWorksStep4'),
                icon: Icons.timer,
                provider: provider,
              ),
              const SizedBox(height: 24),

              // Tech stack credits
              Text(
                context.tr('Credits'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTechRow('Framework', 'Flutter SDK (Dart 3.x)', Icons.phone_android),
                    const Divider(color: Colors.white12, height: 16),
                    _buildTechRow('Database', 'Firebase Realtime Database', Icons.dns),
                    const Divider(color: Colors.white12, height: 16),
                    _buildTechRow('Storage', 'Firebase Cloud Storage', Icons.cloud_upload),
                    const Divider(color: Colors.white12, height: 16),
                    _buildTechRow('AI Copilot', 'Google Gemini Flash API', Icons.auto_awesome),
                    const Divider(color: Colors.white12, height: 16),
                    _buildTechRow('Maps & Routing', 'Google Maps Native SDK', Icons.map),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Changelog
              Text(
                context.tr('Changelog'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'v2.0.0 - Flutter Port (June 2026)',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Rebuilt core workspace from .NET MAUI to Flutter\n'
                      '• Added new image annotation painter with PNG export engine\n'
                      '• Integrated Gemini AI rest agent voice assistant\n'
                      '• Redesigned dual light/dark themes using clean glassmorphism patterns',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'v1.0.0 - MAUI Baseline (Jan 2026)',
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Initial Swedish snowplow routing system\n'
                      '• Basic user auth and chat rooms',
                      style: TextStyle(color: Colors.white30, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNum,
    required String text,
    required IconData icon,
    required ThemeAndLocalizationProvider provider,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: provider.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: provider.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $stepNum',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
