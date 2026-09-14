import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/app_release.dart';
import '../models/budget.dart';
import '../models/task.dart';

class PdfExportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static Future<void> exportExecutiveReport({
    required String appTitle,
    required String organizationName,
    required List<Budget> budgets,
    required List<AppRelease> appReleases,
  }) async {
    final pdf = pw.Document();

    final totalAllocated = budgets.fold(0.0, (sum, b) => sum + b.allocatedBudget);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.totalSpent);
    final totalRemaining = totalAllocated - totalSpent;

    List<Map<String, dynamic>> completedTasks = [];
    for (var b in budgets) {
      for (var t in b.tasks) {
        if (t.status == TaskStatus.completed) {
          completedTasks.add({'budget': b, 'task': t});
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F5132'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GRIMM MARK - RAPPORT FINANCIER & EXÉCUTION',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Application: $appTitle | Organisation: $organizationName',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    _dateFormat.format(DateTime.now()),
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#D4AF37'),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Synthèse Financière Cards
            pw.Text(
              '1. Synthèse Budgétaire Globale (en FCFA)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F5132')),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Budget Total Alloué', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Dépenses Réelles', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Solde Disponible', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_currencyFormat.format(totalAllocated), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_currencyFormat.format(totalSpent), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_currencyFormat.format(totalRemaining), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: totalRemaining >= 0 ? PdfColors.green700 : PdfColors.red))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tableau des Catégories Budgétaires
            pw.Text(
              '2. Répartition par Catégorie Budgétaire',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F5132')),
            ),
            pw.SizedBox(height: 8),
            if (budgets.isEmpty)
              pw.Text('Aucune catégorie budgétaire configurée.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Catégorie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Alloué (FCFA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dépensé (FCFA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Disponible (FCFA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tâches', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...budgets.map((b) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(b.title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currencyFormat.format(b.allocatedBudget), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currencyFormat.format(b.totalSpent), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currencyFormat.format(b.remainingBudget), style: pw.TextStyle(fontSize: 9, color: b.remainingBudget >= 0 ? PdfColors.green700 : PdfColors.red))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${b.completedTasksCount}/${b.tasks.length}', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 20),

            // Tâches Réalisées & Impacts
            pw.Text(
              '3. Bilan des Tâches Exécutées & Impact Obtenu',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F5132')),
            ),
            pw.SizedBox(height: 8),
            if (completedTasks.isEmpty)
              pw.Text('Aucune tâche exécutée pour le moment.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.Column(
                children: completedTasks.map((item) {
                  final budget = item['budget'] as Budget;
                  final task = item['task'] as Task;
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(task.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text('Responsable: ${task.responsible}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.teal)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Budget: ${budget.title} | Prévu: ${_currencyFormat.format(task.allocatedBudget)} | Réel: ${_currencyFormat.format(task.actualSpent > 0 ? task.actualSpent : task.allocatedBudget)}', style: const pw.TextStyle(fontSize: 9)),
                        if (task.receiptNote.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Justificatif / Reçu: ${task.receiptNote}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic)),
                        ],
                        if (task.executionResult.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(color: PdfColors.amber50, borderRadius: pw.BorderRadius.circular(4)),
                            child: pw.Text('Impact: ${task.executionResult}', style: pw.TextStyle(fontSize: 9, color: PdfColors.amber900)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Mises à Jour & Releases
            if (appReleases.isNotEmpty) ...[
              pw.Text(
                '4. Feuille de Route des Mises à Jour Mobile',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F5132')),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Version', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Titre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Statut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date Prévue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...appReleases.map((r) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(r.version, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(r.title, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(r.status.label, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_dateFormat.format(r.targetDate), style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Généré par Grimm Mark Suite Pro', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page 1/1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Bilan_Financier_Grimm_Mark_${_dateFormat.format(DateTime.now()).replaceAll('/', '-')}.pdf',
    );
  }
}
