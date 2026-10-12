import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/storage_service.dart';

/// File-file lokal yang di-backup - kalau nambah fitur baru yang nyimpen
/// data lokal (LocalJsonListStore), tambahin nama filenya di sini juga.
const _backupFiles = [
  'notes.json',
  'todo.json',
  'clipboard_history.json',
  'habits.json',
  'webview_library.json',
  'settings.json',
];

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _busy = false;
  String? _message;
  bool _isError = false;

  Future<void> _backup() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final root = await StorageService.rootPath;
      final bundle = <String, dynamic>{
        'app': 'Kyowi',
        'backupVersion': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'data': <String, dynamic>{},
      };

      for (final fileName in _backupFiles) {
        final file = File('$root/$fileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.trim().isNotEmpty) {
            bundle['data'][fileName] = jsonDecode(content);
          }
        }
      }

      final jsonBytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(bundle)));
      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'kyowi_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        bytes: jsonBytes,
      );

      setState(() {
        _message = savedPath != null ? '✓ Backup tersimpan di: $savedPath' : '✓ Backup selesai dibuat.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Gagal backup: $e';
        _isError = true;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Restore Backup?', style: TextStyle(color: AppColors.ink)),
        content: const Text(
          'Data yang ada sekarang (Notes, Todo, Clipboard History, dll) bakal DITIMPA sama isi file backup. Gak bisa dibalikin kalau belum sempat backup data sekarang.',
          style: TextStyle(color: AppColors.gray, fontSize: 12.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut Restore', style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
        setState(() => _busy = false);
        return;
      }

      final content = utf8.decode(result.files.first.bytes!);
      final bundle = jsonDecode(content) as Map<String, dynamic>;
      if (bundle['app'] != 'Kyowi' || bundle['data'] is! Map) {
        throw Exception('File ini bukan backup Kyowi yang valid.');
      }

      final data = bundle['data'] as Map<String, dynamic>;
      final root = await StorageService.rootPath;
      var restoredCount = 0;
      for (final entry in data.entries) {
        if (!_backupFiles.contains(entry.key)) continue; // skip entry gak dikenal
        final file = File('$root/${entry.key}');
        await file.writeAsString(jsonEncode(entry.value));
        restoredCount++;
      }

      setState(() {
        _message = '✓ $restoredCount file berhasil di-restore. Buka ulang tools terkait buat liat datanya.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Gagal restore: $e';
        _isError = true;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Backup', accent: '& Restore', subtitle: 'Export/import semua data lokal kamu'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.gray, size: 14),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backup mencakup: Notes, Todo List, Clipboard History, Habit Tracker, WebView Library, dan Settings. Simpen file backup di tempat aman (Google Drive, dll) - kalau HP ganti atau app di-uninstall, semua data lokal ilang tanpa ini.',
                  style: TextStyle(color: AppColors.gray, fontSize: 10.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _busy ? null : _backup,
          icon: const Icon(Icons.upload_file, color: Color(0xFF1A120C)),
          label: const Text('BACKUP SEKARANG'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.download, color: AppColors.cyan),
          label: const Text('RESTORE DARI BACKUP', style: TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        ],
        if (_message != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: (_isError ? AppColors.magenta : AppColors.cyan).withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_message!, style: TextStyle(color: _isError ? AppColors.magenta : AppColors.cyan, fontSize: 11.5)),
          ),
        ],
      ],
    );
  }
}
