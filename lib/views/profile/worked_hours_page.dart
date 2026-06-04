import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/timesheet_entry.dart';
import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class WorkedHoursPage extends StatefulWidget {
  const WorkedHoursPage({super.key});

  @override
  State<WorkedHoursPage> createState() => _WorkedHoursPageState();
}

class _WorkedHoursPageState extends State<WorkedHoursPage> {
  final _jobService = JobService();
  bool _isLoading = true;
  List<TimesheetEntry> _allEntries = [];
  Map<String, Job> _jobsMap = {};
  String _selectedPeriod = 'All'; // 'All', 'Month', 'Week'


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        // Fetch jobs to resolve titles
        _jobsMap = await _jobService.getJobsMap();

        // Fetch timesheets based on role
        if (user.role == 'Foreman') {
          _allEntries = await _jobService.getAllTimesheets();
        } else {
          _allEntries = await _jobService.getTimesheetsForWorker(user.id);
        }

        // Sort by date descending
        _allEntries.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      debugPrint('Error loading timesheets: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<TimesheetEntry> get _filteredEntries {
    final now = DateTime.now();
    return _allEntries.where((entry) {
      if (_selectedPeriod == 'Month') {
        return entry.date.year == now.year && entry.date.month == now.month;
      } else if (_selectedPeriod == 'Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfEntry = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return startOfEntry.isAfter(startOfWeekDay.subtract(const Duration(seconds: 1))) &&
            startOfEntry.isBefore(now.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  double get _calculatedTotalHours {
    return _filteredEntries.fold(0.0, (sum, entry) => sum + entry.hoursWorked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isForeman = authService.isForeman;

    final filteredList = _filteredEntries;
    final total = _calculatedTotalHours;

    return BaseScreen(
      title: context.tr('MyWorkedHours'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Summary Glass Card
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Text(
                            context.tr('SelectedMonthHours'),
                            style: TextStyle(
                              color: provider.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${total.toStringAsFixed(1)} ${provider.currentLanguage == 'sv' ? 't' : 'h'}',
                            style: TextStyle(
                              color: provider.primaryColor,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter Segment Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterButton('All', provider.currentLanguage == 'sv' ? 'Alla' : 'All Time', provider),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterButton('Month', provider.currentLanguage == 'sv' ? 'Denna månad' : 'This Month', provider),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterButton('Week', provider.currentLanguage == 'sv' ? 'Denna vecka' : 'This Week', provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timesheet Entries List
                  if (filteredList.isEmpty)
                    Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.timer_off_outlined, size: 48, color: provider.textSecondaryColor),
                            const SizedBox(height: 12),
                            Text(
                              provider.currentLanguage == 'sv' ? 'Inga tidrapporter hittades' : 'No timesheet entries found',
                              style: TextStyle(color: provider.textSecondaryColor, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredList.map((entry) {
                      final job = _jobsMap[entry.jobId];
                      final jobTitle = job?.title ?? 'Unknown Job';
                      final jobCode = job?.jobCode ?? 'N/A';
                      final dateFormatted = DateFormat('yyyy-MM-dd').format(entry.date);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jobTitle,
                                            style: TextStyle(
                                              color: provider.textPrimaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Code: $jobCode',
                                            style: TextStyle(
                                              color: provider.textSecondaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: provider.primaryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: provider.primaryColor.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        '${entry.hoursWorked.toStringAsFixed(1)} ${provider.currentLanguage == 'sv' ? 't' : 'h'}',
                                        style: TextStyle(
                                          color: provider.primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: provider.textSecondaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateFormatted,
                                          style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    if (isForeman)
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: provider.secondaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            entry.workerName,
                                            style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),

                                    ),
                                    child: Text(
                                      entry.notes!,
                                      style: TextStyle(
                                        color: provider.textPrimaryColor.withOpacity(0.8),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterButton(String period, String label, ThemeAndLocalizationProvider provider) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? provider.primaryColor : Colors.black.withOpacity(0.2),
        foregroundColor: isSelected ? Colors.white : provider.textSecondaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? provider.primaryColor : provider.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
