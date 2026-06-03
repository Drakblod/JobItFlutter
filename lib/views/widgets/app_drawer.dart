import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_localization_service.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';

class AppDrawer extends StatelessWidget {
  final int activeJobCount;
  final String activeHomeRoute; // For navigating back to the correct dashboard

  const AppDrawer({
    super.key,
    this.activeJobCount = 0,
    required this.activeHomeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    ImageProvider profileImage;
    if (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty) {
      profileImage = NetworkImage(user.profilePicUrl!);
    } else {
      profileImage = const AssetImage('assets/images/dotnet_bot.png');
    }

    final String statsText = activeJobCount > 0 
        ? context.tr('ActiveJobs', [activeJobCount]) 
        : context.tr('NoActivityYet');

    return Drawer(
      backgroundColor: provider.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: provider.currentTheme == AppThemeType.defaultDark 
                  ? Colors.black.withOpacity(0.3)
                  : provider.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: provider.borderColor.withOpacity(0.5)),
              ),
            ),
            accountName: Text(
              user.displayName,
              style: TextStyle(
                color: provider.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.role == 'Foreman' ? context.tr('Foreman') : context.tr('Worker'),
                  style: TextStyle(color: provider.textSecondaryColor, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  statsText,
                  style: TextStyle(
                    color: provider.textSecondaryColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profileImage,
              backgroundColor: Colors.grey.shade800,
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Home Menu
                ListTile(
                  leading: Icon(Icons.home, color: provider.primaryColor),
                  title: Text(
                    context.tr('HomeTitle'),
                    style: TextStyle(color: provider.textPrimaryColor, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, activeHomeRoute);
                  },
                ),

                // My Profile Menu
                ListTile(
                  leading: Icon(Icons.person, color: provider.primaryColor),
                  title: Text(
                    context.tr('MyProfile'),
                    style: TextStyle(color: provider.textPrimaryColor, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),

                // Workforce List Menu (Foreman only)
                if (authService.isForeman)
                  ListTile(
                    leading: Icon(Icons.people, color: provider.primaryColor),
                    title: Text(
                      context.tr('WorkforceList'),
                      style: TextStyle(color: provider.textPrimaryColor, fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/workforce');
                    },
                  ),

                // Settings Menu
                ListTile(
                  leading: Icon(Icons.settings, color: provider.primaryColor),
                  title: Text(
                    context.tr('SettingsTitle'),
                    style: TextStyle(color: provider.textPrimaryColor, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),

                // About & Help Menu
                ListTile(
                  leading: Icon(Icons.help_outline, color: provider.primaryColor),
                  title: Text(
                    context.tr('AboutAndHelp'),
                    style: TextStyle(color: provider.textPrimaryColor, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
              ],
            ),
          ),

          // Logout Item at the bottom
          Divider(color: provider.borderColor.withOpacity(0.5)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              context.tr('Logout'),
              style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context);
              await authService.signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
