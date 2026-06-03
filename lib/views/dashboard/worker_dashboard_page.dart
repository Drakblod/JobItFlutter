import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  final _jobService = JobService();
  final _codeController = TextEditingController();
  int _activeJobsCount = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showJoinJobDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: provider.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: provider.borderColor),
          ),
          title: Text(
            context.tr('JoinJobTooltip'),
            style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('JobCodePrompt'),
                style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                style: TextStyle(color: provider.textPrimaryColor),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: context.tr('CodePlaceholder'),
                  hintStyle: TextStyle(color: provider.textSecondaryColor),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: provider.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _codeController.clear();
                Navigator.pop(context);
              },
              child: Text(context.tr('Cancel'), style: TextStyle(color: provider.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () => _handleJoinJob(context),
              style: ElevatedButton.styleFrom(backgroundColor: provider.primaryColor),
              child: Text(context.tr('JoinJob'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleJoinJob(BuildContext dialogContext) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('EnterCodeError'))),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final job = await _jobService.getJobByCode(code);
      if (job == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('InvalidCodeError'))),
          );
        }
        return;
      }

      if (job.assignedWorkers.containsKey(user.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('AlreadyAssignedMessage'))),
          );
        }
        _codeController.clear();
        Navigator.pop(dialogContext);
        return;
      }

      // Assign worker to job
      await _jobService.assignJob(job.id, user.id, user.displayName);
      
      _codeController.clear();
      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('JoinedSuccess'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('JoinJobError')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<List<Job>>(
      stream: _jobService.streamActiveJobsForWorker(user.id),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? [];
        
        // Update active jobs count for drawer info
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeJobsCount != jobs.length) {
            setState(() {
              _activeJobsCount = jobs.length;
            });
          }
        });

        return BaseScreen(
          title: context.tr('WorkerDashboardTitle'),
          drawer: AppDrawer(
            activeHomeRoute: '/worker',
            activeJobCount: _activeJobsCount,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showJoinJobDialog,
            backgroundColor: provider.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.group_add),
            label: Text(context.tr('JoinJob')),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Banner
                const SizedBox(height: 10),
                Text(
                  '${context.tr('HomeTitle')}, ${user.displayName}!',
                  style: TextStyle(
                    color: provider.textPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.tr('NoActivityYet').replaceAll('No activity yet', 'Here are your active construction sites:'),
                  style: TextStyle(
                    color: provider.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Jobs List
                Expanded(
                  child: jobs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late, size: 64, color: provider.textSecondaryColor),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('NoAssignedJobs'),
                                style: TextStyle(color: provider.textSecondaryColor, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/job_details',
                                    arguments: job.id,
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              job.title,
                                              style: TextStyle(
                                                color: provider.textPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: job.jobType == 'Snowracer'
                                                  ? Colors.cyan.withOpacity(0.2)
                                                  : provider.primaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: job.jobType == 'Snowracer'
                                                    ? Colors.cyan
                                                    : provider.primaryColor,
                                              ),
                                            ),
                                            child: Text(
                                              job.jobType == 'Snowracer'
                                                  ? context.tr('SnowracerJob')
                                                  : context.tr('StandardJob'),
                                              style: TextStyle(
                                                color: job.jobType == 'Snowracer'
                                                    ? Colors.cyanAccent
                                                    : provider.textPrimaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        context.tr('DescriptionFormat', [job.description]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: provider.textSecondaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: provider.primaryColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              job.address,
                                              style: TextStyle(
                                                color: provider.textPrimaryColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              job.jobCode,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
