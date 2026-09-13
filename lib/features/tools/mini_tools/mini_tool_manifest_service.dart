import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/storage/storage_service.dart';

class MiniTool {
  final String id;
  final String name;
  final String desc;
  final String icon; // nama icon Material, di-mapping ke IconData
  final String url;
  final String category;

  MiniTool({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.url,
    required this.category,
  });

  factory MiniTool.fromJson(Map<String, dynamic> json) => MiniTool(
        id: json['id'] as String,
        name: json['name'] as String,
        desc: json['desc'] as String,
        icon: json['icon'] as String? ?? 'extension',
        url: json['url'] as String,
        category: json['category'] as String? ?? 'Web Tools',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
        'icon': icon,
        'url': url,
        'category': category,
      };

  static const Map<String, IconData> _iconMap = {
    'extension': Icons.extension_outlined,
    'calculate': Icons.calculate_outlined,
    'text_fields': Icons.text_fields,
    'palette': Icons.palette_outlined,
    'schedule': Icons.schedule,
    'translate': Icons.translate,
    'straighten': Icons.straighten,
    'games': Icons.games_outlined,
    'code': Icons.code,
    'image': Icons.image_outlined,
    'link': Icons.link,
    'note': Icons.note_outlined,
  };

  IconData get iconData => _iconMap[icon] ?? Icons.extension_outlined;
}

/// Fetch daftar "mini tools" dari manifest JSON yang di-hosting di internet
/// (misal raw.githubusercontent.com). Ini yang bikin tools baru bisa
/// langsung muncul di app pengguna tanpa update APK - cukup upload file
/// HTML baru + tambahin entrinya di manifest.json.
///
/// Manifest di-cache lokal biar tetep ada tampilan meski lagi offline
/// atau fetch gagal (graceful degradation, gak nge-blank).
class MiniToolManifestService {
  static const String manifestUrl =
      'https://raw.githubusercontent.com/phimst/seraphapps-tools/main/manifest.json';
  static const String _cacheFileName = 'mini_tools_cache.json';

  static Future<List<MiniTool>> fetch() async {
    try {
      final res = await http.get(Uri.parse(manifestUrl));
      if (res.statusCode != 200) throw Exception('Server error (${res.statusCode})');
      final List<dynamic> data = jsonDecode(res.body);
      final tools = data.map((e) => MiniTool.fromJson(e as Map<String, dynamic>)).toList();
      // Simpan cache biar bisa dipake offline lain kali.
      await _saveCache(data);
      return tools;
    } catch (e) {
      // Fetch gagal (offline / manifest belum ada) -> coba pake cache lama.
      final cached = await _loadCache();
      if (cached != null) return cached;
      return []; // belum pernah berhasil fetch sama sekali -> kosong, gak error ke user
    }
  }

  static Future<void> _saveCache(List<dynamic> rawData) async {
    try {
      final root = await StorageService.rootPath;
      final file = File('$root/$_cacheFileName');
      await file.writeAsString(jsonEncode(rawData));
    } catch (_) {
      // Gagal simpan cache bukan hal fatal, diemin aja.
    }
  }

  static Future<List<MiniTool>?> _loadCache() async {
    try {
      final root = await StorageService.rootPath;
      final file = File('$root/$_cacheFileName');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> data = jsonDecode(content);
      return data.map((e) => MiniTool.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
