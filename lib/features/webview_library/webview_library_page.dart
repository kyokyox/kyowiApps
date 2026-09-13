import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/seraph_header.dart';
import '../../core/storage/local_json_list_store.dart';
import 'web_snippet.dart';
import 'web_snippet_editor_page.dart';
import 'web_snippet_viewer_page.dart';

enum _PageMode { normal, edit, delete }

class WebviewLibraryPage extends StatefulWidget {
  const WebviewLibraryPage({super.key});

  @override
  State<WebviewLibraryPage> createState() => _WebviewLibraryPageState();
}

class _WebviewLibraryPageState extends State<WebviewLibraryPage> with SingleTickerProviderStateMixin {
  static const _store = LocalJsonListStore('webview_library.json');
  List<WebSnippet> _snippets = [];
  bool _loading = true;

  _PageMode _mode = _PageMode.normal;
  final Set<String> _selectedIds = {};

  late final AnimationController _fabController;
  bool get _fabExpanded => _fabController.value > 0.5;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _load();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await _store.load();
    setState(() {
      _snippets = raw.map(WebSnippet.fromJson).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _loading = false;
    });
  }

  Future<void> _persist() => _store.save(_snippets.map((s) => s.toJson()).toList());

  void _toggleFab() {
    if (_fabExpanded) {
      _fabController.reverse();
    } else {
      _fabController.forward();
    }
  }

  void _closeFab() {
    if (_fabExpanded) _fabController.reverse();
  }

  void _startCreate() async {
    _closeFab();
    final result = await Navigator.of(context).push<WebSnippet>(
      MaterialPageRoute(builder: (_) => const WebSnippetEditorPage()),
    );
    if (result != null) {
      setState(() => _snippets.insert(0, result));
      _persist();
    }
  }

  void _startEditMode() {
    _closeFab();
    setState(() {
      _mode = _mode == _PageMode.edit ? _PageMode.normal : _PageMode.edit;
      _selectedIds.clear();
    });
  }

  void _startDeleteMode() {
    _closeFab();
    setState(() {
      _mode = _mode == _PageMode.delete ? _PageMode.normal : _PageMode.delete;
      _selectedIds.clear();
    });
  }

  void _exitMode() {
    setState(() {
      _mode = _PageMode.normal;
      _selectedIds.clear();
    });
  }

  void _onCardTap(WebSnippet snippet) async {
    if (_mode == _PageMode.edit) {
      final result = await Navigator.of(context).push<WebSnippet>(
        MaterialPageRoute(builder: (_) => WebSnippetEditorPage(existing: snippet)),
      );
      if (result != null) {
        setState(() {
          final idx = _snippets.indexWhere((s) => s.id == result.id);
          if (idx >= 0) _snippets[idx] = result;
          _snippets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
        _persist();
      }
      _exitMode();
    } else if (_mode == _PageMode.delete) {
      setState(() {
        if (_selectedIds.contains(snippet.id)) {
          _selectedIds.remove(snippet.id);
        } else {
          _selectedIds.add(snippet.id);
        }
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebSnippetViewerPage(snippet: snippet)),
      );
    }
  }

  void _confirmDelete() {
    if (_selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Hapus?', style: TextStyle(color: AppColors.ink)),
        content: Text('Hapus ${_selectedIds.length} halaman terpilih? Gak bisa dibalikin lagi.',
            style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _snippets.removeWhere((s) => _selectedIds.contains(s.id));
              });
              _persist();
              _exitMode();
            },
            child: const Text('Yes, Hapus', style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _mode == _PageMode.delete
          ? AppBar(
              title: Text('${_selectedIds.length} dipilih', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              leading: IconButton(icon: const Icon(Icons.close, color: AppColors.ink), onPressed: _exitMode),
              actions: [
                TextButton(
                  onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
                  child: Text('Hapus',
                      style: TextStyle(
                          color: _selectedIds.isEmpty ? AppColors.gray : AppColors.magenta,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            )
          : _mode == _PageMode.edit
              ? AppBar(
                  title: const Text('Mode Edit - tap halaman buat edit', style: TextStyle(fontSize: 12, color: AppColors.ink)),
                  leading: IconButton(icon: const Icon(Icons.close, color: AppColors.ink), onPressed: _exitMode),
                )
              : null,
      body: SafeArea(
        child: Stack(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                    children: [
                      if (_mode == _PageMode.normal)
                        const SeraphHeader(title: 'Web', accent: 'View', subtitle: 'Halaman HTML kamu sendiri, bisa dibuka offline'),
                      if (_snippets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Center(
                              child: Text('Belum ada halaman. Tap + buat bikin.',
                                  style: TextStyle(color: AppColors.gray, fontSize: 12))),
                        )
                      else
                        for (final snippet in _snippets) _snippetCard(snippet),
                    ],
                  ),
            _buildFabMenu(),
          ],
        ),
      ),
    );
  }

  Widget _snippetCard(WebSnippet snippet) {
    final selected = _selectedIds.contains(snippet.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.cyan.withValues(alpha: 0.12) : AppColors.panel,
        border: Border.all(color: selected ? AppColors.cyan : AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onCardTap(snippet),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (_mode == _PageMode.delete) ...[
                Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? AppColors.cyan : AppColors.gray, size: 20),
                const SizedBox(width: 10),
              ] else ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.code, color: AppColors.cyan, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(snippet.title,
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                    if (snippet.desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(snippet.desc,
                          style: const TextStyle(color: AppColors.gray, fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (_mode == _PageMode.normal) const Icon(Icons.chevron_right, color: AppColors.gray),
              if (_mode == _PageMode.edit) const Icon(Icons.edit, color: AppColors.cyan, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabMenu() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        final t = _fabController.value;
        return Stack(
          children: [
            // Backdrop buat nutup menu kalau tap di luar
            if (t > 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeFab,
                  child: Container(color: Colors.black.withValues(alpha: 0.35 * t)),
                ),
              ),
            _miniFab(t, offset: 1, icon: Icons.add_box_outlined, label: 'Buat', color: AppColors.cyan, onTap: _startCreate),
            _miniFab(t, offset: 2, icon: Icons.edit_outlined, label: 'Edit', color: Colors.orangeAccent, onTap: _startEditMode),
            _miniFab(t, offset: 3, icon: Icons.delete_outline, label: 'Hapus', color: AppColors.magenta, onTap: _startDeleteMode),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                heroTag: 'wb_main_fab',
                backgroundColor: AppColors.cyan,
                onPressed: _toggleFab,
                child: Transform.rotate(
                  angle: t * 0.75 * math.pi, // muter ~135 derajat pas dibuka
                  child: const Icon(Icons.add, color: Color(0xFF1A120C)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mini FAB yang gerak serong ke kiri-atas dari posisi FAB utama pas
  /// di-expand, jarak makin jauh sesuai [offset] (1=paling deket, 3=paling jauh).
  Widget _miniFab(double t, {required int offset, required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    const step = 62.0; // jarak antar mini-fab di sepanjang diagonal
    final distance = step * offset * t;
    // Gerak serong kiri-atas: X berkurang, Y berkurang (dari posisi FAB utama)
    final dx = distance * 0.75;
    final dy = distance * 1.0;

    return Positioned(
      right: 20 + dx,
      bottom: 20 + dy,
      child: Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.5 + (t * 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (t > 0.6)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.line)),
                  child: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 11)),
                ),
              FloatingActionButton.small(
                heroTag: 'wb_mini_$label',
                backgroundColor: color,
                onPressed: t > 0.5 ? onTap : null,
                child: Icon(icon, color: const Color(0xFF1A120C), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
