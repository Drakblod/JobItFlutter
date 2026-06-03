import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/timesheet_entry.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class LogHoursPage extends StatefulWidget {
  final String jobId;
  const LogHoursPage({super.key, required this.jobId});

  @override
  State<LogHoursPage> createState() => _LogHoursPageState();
}

class _LogHoursPageState extends State<LogHoursPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _jobService = JobService();

  DateTime _selectedDate = DateTime.now();
  double _hoursWorked = 8.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: provider.primaryColor,
              onPrimary: Colors.white,
              surface: provider.backgroundColor,
              onSurface: provider.textPrimaryColor,
            ),
            dialogBackgroundColor: provider.backgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    if (_hoursWorked <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('InvalidHours'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final entry = TimesheetEntry(
        id: '', // Push ID
        jobId: widget.jobId,
        workerId: user.id,
        workerName: user.displayName,
        hoursWorked: _hoursWorked,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      await _jobService.logHours(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('LoggedHoursSuccess', [_hoursWorked.toStringAsFixed(1)]))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log hours: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('LogHoursTitle'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('LogHours'),
                      style: TextStyle(
                        color: provider.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Date Picker Select
                    Text(
                      context.tr('SelectDate'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: provider.borderColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: TextStyle(color: provider.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.calendar_today, color: provider.primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hours Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('HoursWorked'),
                          style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                        ),
                        Text(
                          context.tr('HoursFormat', [_hoursWorked]),
                          style: TextStyle(color: provider.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _hoursWorked,
                      min: 0.5,
                      max: 24.0,
                      divisions: 47, // 0.5 step increments
                      activeColor: provider.primaryColor,
                      inactiveColor: provider.borderColor.withOpacity(0.3),
                      label: _hoursWorked.toStringAsFixed(1),
                      onChanged: (double val) {
                        setState(() {
                          _hoursWorked = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Notes Optional Field
                    Text(
                      context.tr('NotesOptional'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('WorkNotesPlaceholder'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                    : Text(
                        context.tr('SaveLog'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
