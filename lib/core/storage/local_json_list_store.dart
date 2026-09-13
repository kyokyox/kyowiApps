import 'dart:convert';
import 'dart:io';
import '../storage/storage_service.dart';

/// Helper generic buat baca/simpen list data JSON ke file lokal di
/// storage app. Dipake beberapa tools yang butuh persist data sederhana
/// (Notes, Todo List, Clipboard History) - daripada nulis ulang logic
/// baca/tulis file di tiap tools.
class LocalJsonListStore {
  final String fileName;
  const LocalJsonListStore(this.fileName);

  Future<List<Map<String, dynamic>>> load() async {
    try {
      final root = await StorageService.rootPath;
      final file = File('$root/$fileName');
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> data = jsonDecode(content);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, dynamic>> items) async {
    final root = await StorageService.rootPath;
    final file = File('$root/$fileName');
    await file.writeAsString(jsonEncode(items));
  }
}
