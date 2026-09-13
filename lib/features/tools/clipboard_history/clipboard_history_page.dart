import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/local_json_list_store.dart';

class _ClipEntry {
  String text;
  int savedAt;
  _ClipEntry({required this.text, required this.savedAt});

  factory _ClipEntry.fromJson(Map<String, dynamic> j) =>
      _ClipEntry(text: j['text'] as String? ?? '', savedAt: j['savedAt'] as int? ?? 0);

  Map<String, dynamic> toJson() => {'text': text, 'savedAt': savedAt};
}

/// Catatan teknis: Android 10+ ngebatesin app baca clipboard diem-diem di
/// background (alasan privasi) - jadi histori ini cuma ke-capture pas
/// user BUKA tool ini atau tekan tombol "Tangkap dari Clipboard" secara
/// manual, bukan otomatis 24/7 di background.
class ClipboardHistoryPage extends StatefulWidget {
  const ClipboardHistoryPage({super.key});

  @override
  State<ClipboardHistoryPage> createState() => _ClipboardHistoryPageState();
}

class _ClipboardHistoryPageState extends State<ClipboardHistoryPage> with WidgetsBindingObserver {
  static const _store = LocalJsonListStore('clipboard_history.json');
  List<_ClipEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _captureClipboard();
  }

  Future<void> _load() async {
    final raw = await _store.load();
    setState(() {
      _history = raw.map(_ClipEntry.fromJson).toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      _loading = false;
    });
    _captureClipboard();
  }

  Future<void> _persist() => _store.save(_history.map((e) => e.toJson()).toList());

  Future<void> _captureClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return;
      if (_history.isNotEmpty && _history.first.text == text) return; // udah ke-capture

      setState(() {
        _history.insert(0, _ClipEntry(text: text, savedAt: DateTime.now().millisecondsSinceEpoch));
        if (_history.length > 50) _history = _history.sublist(0, 50); // batasin histori
      });
      _persist();
    } catch (_) {
      // Gagal akses clipboard (jarang, tapi jangan crash)
    }
  }

  void _copy(_ClipEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  void _delete(_ClipEntry entry) {
    setState(() => _history.remove(entry));
    _persist();
  }

  void _clearAll() {
    setState(() => _history.clear());
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(
            title: 'Clipboard',
            accent: 'History',
            subtitle: 'Histori teks yang pernah di-copy'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _captureClipboard,
                icon: const Icon(Icons.content_paste, size: 16, color: AppColors.cyan),
                label: const Text('Tangkap dari Clipboard', style: TextStyle(color: AppColors.ink, fontSize: 11.5)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
              ),
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.magenta),
                tooltip: 'Hapus semua',
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Android membatasi baca clipboard otomatis di background - histori kecapture pas tool ini dibuka.',
          style: TextStyle(color: AppColors.gray, fontSize: 9.5, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.cyan))
        else if (_history.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('Belum ada histori.', style: TextStyle(color: AppColors.gray, fontSize: 12))),
          )
        else
          for (final entry in _history) _entryCard(entry),
      ],
    );
  }

  Widget _entryCard(_ClipEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(entry.text,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => _copy(entry), child: const Icon(Icons.copy, size: 15, color: AppColors.cyan)),
          const SizedBox(width: 10),
          GestureDetector(
              onTap: () => _delete(entry), child: const Icon(Icons.close, size: 15, color: AppColors.gray)),
        ],
      ),
    );
  }
}
