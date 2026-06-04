import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/theme_localization_service.dart';
import '../../services/firebase_parser.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class WorkerListPage extends StatefulWidget {
  const WorkerListPage({super.key});

  @override
  State<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends State<WorkerListPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('WorkforceListTitle'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 24,
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search workers...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(Icons.clear, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),

          // Worker list streaming
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading workforce: ${snapshot.error}',
                      style: TextStyle(color: provider.textPrimaryColor),
                    ),
                  );
                }

                final event = snapshot.data;
                final List<AppUser> allUsers = [];

                if (event != null && event.snapshot.exists) {
                  final data = FirebaseParser.convertToMap(event.snapshot.value);
                  data.forEach((key, val) {
                    try {
                      if (val is Map) {
                        allUsers.add(AppUser.fromJson(val, key));
                      }
                    } catch (e) {
                      debugPrint('Error parsing user $key: $e');
                    }
                  });
                }

                // Filter by search query
                final filteredUsers = allUsers.where((user) {
                  final name = user.displayName.toLowerCase();
                  final email = user.email.toLowerCase();
                  final role = user.role.toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      role.contains(_searchQuery);
                }).toList();

                // Sort: Foreman first, then alphabetical display name
                filteredUsers.sort((a, b) {
                  if (a.role != b.role) {
                    return a.role == 'Foreman' ? -1 : 1;
                  }
                  return a.displayName.compareTo(b.displayName);
                });

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr('NoWorkersFound'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isForeman = user.role == 'Foreman';
                    final roleLabel = isForeman ? context.tr('Foreman') : context.tr('Worker');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _buildAvatar(user, provider),
                          title: Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isForeman
                                      ? Colors.purple.withOpacity(0.3)
                                      : Colors.cyan.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isForeman ? Colors.purpleAccent : Colors.cyanAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: TextStyle(
                                    color: isForeman ? Colors.purpleAccent : Colors.cyanAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () => _showWorkerDetails(user, roleLabel, provider),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppUser user, ThemeAndLocalizationProvider provider) {
    if (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(user.profilePicUrl!),
      );
    }

    // Custom initials fallback
    final initials = user.displayName.split(' ').map((e) => e.isEmpty ? '' : e[0]).join().toUpperCase();
    final cleanInitials = initials.length > 2 ? initials.substring(0, 2) : initials;

    return CircleAvatar(
      radius: 26,
      backgroundColor: provider.primaryColor.withOpacity(0.2),
      child: Text(
        cleanInitials.isEmpty ? 'U' : cleanInitials,
        style: TextStyle(
          color: provider.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  void _showWorkerDetails(AppUser user, String roleLabel, ThemeAndLocalizationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              _buildAvatar(user, provider),
              const SizedBox(height: 16),

              // Name
              Text(
                user.displayName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),

              // Role Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: user.role == 'Foreman'
                      ? Colors.purple.withOpacity(0.3)
                      : Colors.cyan.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user.role == 'Foreman' ? Colors.purpleAccent : Colors.cyanAccent,
                  ),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: user.role == 'Foreman' ? Colors.purpleAccent : Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Info
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phone', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          user.phone ?? 'Not provided',
                          style: TextStyle(
                            color: user.phone != null ? Colors.white : Colors.white54,
                            fontSize: 16,
                            fontStyle: user.phone == null ? FontStyle.italic : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
