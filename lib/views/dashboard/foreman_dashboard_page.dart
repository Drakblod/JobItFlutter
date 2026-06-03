import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';
import '../job/create_job_page.dart';

class ForemanDashboardPage extends StatefulWidget {
  const ForemanDashboardPage({super.key});

  @override
  State<ForemanDashboardPage> createState() => _ForemanDashboardPageState();
}

class _ForemanDashboardPageState extends State<ForemanDashboardPage> {
  final _jobService = JobService();
  bool _showArchived = false;
  int _activeJobsCount = 0;

  Future<void> _handleDeleteJob(String jobId) async {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: provider.backgroundColor,
        title: Text(context.tr('ConfirmTitle'), style: TextStyle(color: provider.textPrimaryColor)),
        content: Text(
          context.tr('DeleteJobConfirmMessage'),
          style: TextStyle(color: provider.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('CancelLabel'), style: TextStyle(color: provider.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _jobService.deleteJob(jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('JobDeletedSuccess'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('DeleteJobError')}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      body: StreamBuilder<List<Job>>(
        stream: _showArchived 
            ? Stream.fromFuture(_jobService.getArchivedJobs(user.id)) 
            : _jobService.streamActiveJobsForForeman(user.id),
        builder: (context, snapshot) {
          final jobs = snapshot.data ?? [];

          // Keep track of active jobs count for drawer
          if (!_showArchived) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _activeJobsCount != jobs.length) {
                setState(() {
                  _activeJobsCount = jobs.length;
                });
              }
            });
          }

          return BaseScreen(
            title: context.tr('ForemanDashboardTitle'),
            drawer: AppDrawer(
              activeHomeRoute: '/foreman',
              activeJobCount: _activeJobsCount,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateJobPage()),
                );
              },
              backgroundColor: provider.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(context.tr('CreateJobTitle')),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Welcome and Filter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${context.tr('HomeTitle')}, ${user.displayName}!',
                              style: TextStyle(
                                color: provider.textPrimaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _showArchived ? context.tr('ArchivedJobs') : 'Manage your active worksites:',
                              style: TextStyle(
                                color: provider.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Archive Switcher Button
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showArchived = !_showArchived;
                          });
                        },
                        icon: Icon(
                          _showArchived ? Icons.checklist : Icons.archive,
                          color: provider.secondaryColor,
                          size: 18,
                        ),
                        label: Text(
                          _showArchived ? 'Active Jobs' : context.tr('ArchivedJobs'),
                          style: TextStyle(
                            color: provider.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Jobs List
                  Expanded(
                    child: jobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.work_off, size: 64, color: provider.textSecondaryColor),
                                const SizedBox(height: 16),
                                Text(
                                  _showArchived 
                                      ? context.tr('NoArchivedJobs') 
                                      : context.tr('NoJobs'),
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
                                            Row(
                                              children: [
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
                                                const SizedBox(width: 8),
                                                // Delete button (Foreman only)
                                                if (!_showArchived)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _handleDeleteJob(job.id),
                                                  ),
                                              ],
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
      ),
    );
  }
}
