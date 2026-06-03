import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/subtask.dart';
import '../models/job_image.dart';

class PdfService {
  Future<void> generateAndShareJobReport(
    Job job,
    List<Subtask> subtasks,
    List<JobImage> images,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'JobIt Workforce Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Job Code: ${job.jobCode}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Status: ${job.status}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey400),
            pw.SizedBox(height: 16),

            // General Info Section
            pw.Text(
              'General Information',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Title: ${job.title}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Description: ${job.description}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Location: ${job.address}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),

            // Workers Section
            pw.Text(
              'Assigned Workers',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 8),
            if (job.assignedWorkers.isNotEmpty)
              ...job.assignedWorkers.values.map(
                (workerName) => pw.Row(
                  children: [
                    pw.Bullet(bulletColor: PdfColors.red800, bulletSize: 4),
                    pw.SizedBox(width: 6),
                    pw.Text(workerName, style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else
              pw.Text('No workers assigned.', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),

            // Subtasks Section Table
            pw.Text(
              'Subtasks & Progress',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                outside: const pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Task', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Table Rows
                for (int i = 0; i < subtasks.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${i + 1}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(subtasks[i].title),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          subtasks[i].isCompleted ? 'DONE' : 'PENDING',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: subtasks[i].isCompleted ? PdfColors.green800 : PdfColors.red800,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Gallery metadata Section (Listing photo upload records)
            if (images.isNotEmpty) ...[
              pw.NewPage(),
              pw.Text(
                'Photo Gallery Meta',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey400)),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Uploaded By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Uploaded At', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  for (var img in images)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(img.uploadedBy),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(img.uploadedAt)),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    try {
      // Print/Share using printing package directly
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Report_${job.jobCode}_${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint('Error generating/sharing PDF report: $e');
    }
  }
}
