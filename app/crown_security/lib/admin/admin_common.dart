import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import '../core/api.dart';

class BulkUploadButton extends StatefulWidget {
  final String bulkUrl; // e.g. '/attendance/bulk'
  final String? singleUrl; // e.g. '/attendance' for per-row uploads
  final Map<String, String>? headerMap; // optional header to backend key mapping
  final Map<String, dynamic> extraFields; // e.g. { 'site_id': currentSiteId }
  final List<String>? templateHeaders; // optional headers for CSV template helper
  final VoidCallback? onDone;
  const BulkUploadButton({
    super.key,
    required this.bulkUrl,
    this.singleUrl,
    this.headerMap,
    this.extraFields = const {},
    this.templateHeaders,
    this.onDone,
  });

  @override
  State<BulkUploadButton> createState() => _BulkUploadButtonState();
}

class _BulkUploadButtonState extends State<BulkUploadButton> {
  bool _busy = false;

  // Excel serial date (days since 1899-12-30) to ISO string (YYYY-MM-DD)
  String _excelSerialToIsoDate(num serial) {
    // Excel incorrectly treats 1900 as leap year; most libs use 1899-12-30 base
    final base = DateTime(1899, 12, 30);
    final dt = base.add(Duration(days: serial.floor()));
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickAndUpload() async {
    try {
      setState(() => _busy = true);
      final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['csv','xlsx']);
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('File data not available');

      List<Map<String, dynamic>> items = [];
      final ext = (file.extension ?? '').toLowerCase();
      if (ext == 'csv') {
        final csvStr = utf8.decode(bytes);
        final rows = const CsvToListConverter(eol: '\n').convert(csvStr);
        if (rows.isEmpty) throw Exception('CSV has no rows');
        final headers = rows.first.map((e) => e.toString()).toList();
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          final map = <String, dynamic>{};
          for (var c = 0; c < headers.length && c < row.length; c++) {
            final key = widget.headerMap?[headers[c]] ?? headers[c];
            map[key] = row[c];
          }
          map.addAll(widget.extraFields);
          items.add(map);
        }
      } else if (ext == 'xlsx') {
        final excel = xlsx.Excel.decodeBytes(bytes);
        final sheet = excel.tables.values.isNotEmpty ? excel.tables.values.first : null;
        if (sheet == null || sheet.rows.isEmpty) throw Exception('Sheet is empty');
        final headers = sheet.rows.first.map((cell) => (cell?.value ?? '').toString()).toList();
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final map = <String, dynamic>{};
          for (var c = 0; c < headers.length && c < row.length; c++) {
            final header = headers[c];
            final key = widget.headerMap?[header] ?? header;
            final val = row[c]?.value;
            dynamic out = val is xlsx.TextCellValue ? val.value : val;
            final lower = key.toString().toLowerCase();
            if (out is num && (lower.contains('date') || lower == 'month')) {
              final iso = _excelSerialToIsoDate(out);
              out = lower == 'month' ? iso.substring(0, 7) : iso; // YYYY-MM for month
            }
            map[key] = out;
          }
          map.addAll(widget.extraFields);
          items.add(map);
        }
      } else {
        throw Exception('Unsupported file type');
      }

      if (items.isEmpty) throw Exception('No rows to upload');
      // Decide mode if singleUrl provided
      bool perRow = false;
      if (widget.singleUrl != null) {
        if (!mounted) return;
        perRow = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Upload mode'),
                content: const Text('Choose bulk for speed, or per-row for a detailed success/error report.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bulk')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Per-row report')),
                ],
              ),
            ) ?? false;
      }

      if (!perRow) {
  await Api.dio.post(widget.bulkUrl, data: items);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk upload completed')));
  widget.onDone?.call();
      } else {
        final singleUrl = widget.singleUrl!;
        final results = <int, String?>{}; // index -> error message or null for success
        for (var i = 0; i < items.length; i++) {
          try {
            await Api.dio.post(singleUrl, data: items[i]);
            results[i] = null;
          } catch (e) {
            results[i] = e.toString();
          }
        }
        final success = results.values.where((v) => v == null).length;
        final failed = results.length - success;
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) {
            final failures = results.entries.where((e) => e.value != null).take(20).toList();
            return AlertDialog(
              title: Text('Upload finished • $success ok, $failed failed'),
              content: failures.isEmpty
                  ? const Text('All rows imported successfully.')
                  : SizedBox(
                      width: 480,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: failures
                              .map((e) => Text('Row ${e.key + 2}: ${e.value}'))
                              .toList(),
                        ),
                      ),
                    ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            );
          },
        );
  widget.onDone?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _busy ? null : _pickAndUpload,
          icon: const Icon(Icons.upload_file),
          label: Text(_busy ? 'Uploading...' : 'Import CSV/XLSX'),
        ),
        if (widget.templateHeaders != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'CSV template',
            icon: const Icon(Icons.description_outlined),
            onPressed: _busy ? null : _showTemplate,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Download sample CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: _busy ? null : _downloadSample,
          ),
        ]
      ],
    );
  }

  void _showTemplate() {
    final headers = widget.templateHeaders!;
    final csv = headers.join(',');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Headers (first row):'),
            const SizedBox(height: 8),
            SelectableText(csv),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Capture navigator and messenger before the async gap to avoid using context afterwards
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.maybeOf(ctx) ?? ScaffoldMessenger.maybeOf(context);
              await Clipboard.setData(ClipboardData(text: csv));
              nav.pop();
              messenger?.showSnackBar(const SnackBar(content: Text('Copied headers to clipboard')));
            },
            child: const Text('Copy headers'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _downloadSample() async {
    try {
      final headers = widget.templateHeaders!;
      // Build one sample data row using extraFields where available
      final values = headers.map((h) {
        final key = widget.headerMap?[h] ?? h;
        final v = widget.extraFields[key];
        if (v != null) return v.toString();
        // Provide reasonable dummies for common columns
        final lc = key.toLowerCase();
        if (lc.contains('date')) return DateTime.now().toIso8601String().substring(0,10);
        if (lc == 'month') return DateTime.now().toIso8601String().substring(0,7);
        if (lc.contains('amount')) return '1000';
        if (lc.contains('status')) return 'PENDING';
        if (lc.contains('rating')) return '4.5';
        if (lc.contains('nps')) return '8';
        if (lc.contains('guard')) return '2';
        if (lc.contains('shift')) return 'DAY';
        if (lc.contains('description')) return 'Sample item';
        if (lc.contains('findings')) return 'All good';
        if (lc.contains('topics')) return 'Discipline, Safety';
        return key;
      }).toList();
      final csv = [headers.join(','), values.join(',')].join('\n');
      final bytes = Uint8List.fromList(utf8.encode(csv));
  await FileSaver.instance.saveFile(name: 'sample.csv', bytes: bytes, ext: 'csv', mimeType: MimeType.csv);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample CSV downloaded')));
    } catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }
}
