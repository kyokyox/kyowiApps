import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/seraph_header.dart';
import 'tool_category.dart';
import 'category_tools_page.dart';
import 'tiktok/tiktok_downloader_page.dart';
import 'github/github_push_page.dart';
import 'encryptor/encryptor_page.dart';
import 'base64/base64_tool_page.dart';
import 'ip_tracker/ip_tracker_page.dart';
import 'tts/tts_page.dart';
import 'disaster/disaster_page.dart';
import 'steganography/steganography_page.dart';
import 'api_tester/api_tester_page.dart';
import 'json_formatter/json_formatter_page.dart';
import 'regex_tester/regex_tester_page.dart';
import 'hash_generator/hash_generator_page.dart';
import 'qr_tool/qr_tool_page.dart';
import 'converter/converter_page.dart';
import 'weather/weather_page.dart';
import 'aes_text/aes_text_page.dart';
import 'password_generator/password_generator_page.dart';
import 'file_browser/file_browser_page.dart';
import 'mini_tools/mini_tool_manifest_service.dart';
import 'mini_tools/mini_tool_viewer_page.dart';
import 'notes/notes_page.dart';
import 'todo_list/todo_list_page.dart';
import 'clipboard_history/clipboard_history_page.dart';
import 'word_counter/word_counter_page.dart';
import 'text_case_converter/text_case_converter_page.dart';
import 'markdown_previewer/markdown_previewer_page.dart';
import 'image_compressor/image_compressor_page.dart';
import 'color_picker/color_picker_page.dart';
import 'scientific_calculator/scientific_calculator_page.dart';
import 'timezone_converter/timezone_converter_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  // Tools bawaan yang ke-bundle di APK - ini butuh update APK biasa kalau
  // mau nambah/ubah.
  static final List<ToolCategory> builtInCategories = [
    ToolCategory(
      title: 'Downloader',
      desc: 'Download konten dari internet',
      icon: Icons.download_outlined,
      tools: [
        ToolEntry(
          icon: Icons.music_note_outlined,
          name: 'TikTok Downloader',
          desc: 'Download video/audio TikTok tanpa watermark',
          builder: (_) => const TikTokDownloaderPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Developer Tools',
      desc: 'Buat kebutuhan development',
      icon: Icons.code_outlined,
      tools: [
        ToolEntry(
          icon: Icons.upload_file_outlined,
          name: 'GitHub Push',
          desc: 'Upload ZIP dan push langsung ke repository',
          builder: (_) => const GithubPushPage(),
        ),
        ToolEntry(
          icon: Icons.enhanced_encryption_outlined,
          name: 'Code Encryptor',
          desc: 'Obfuscate HTML, PHP, CSS, JS',
          builder: (_) => const EncryptorPage(),
        ),
        ToolEntry(
          icon: Icons.code,
          name: 'Base64 Encoder/Decoder',
          desc: 'Convert teks ke Base64 dan sebaliknya',
          builder: (_) => const Base64ToolPage(),
        ),
        ToolEntry(
          icon: Icons.http,
          name: 'API Tester',
          desc: 'Mini-Postman, test API langsung dari app',
          builder: (_) => const ApiTesterPage(),
        ),
        ToolEntry(
          icon: Icons.data_object,
          name: 'JSON Formatter',
          desc: 'Rapiin & validasi JSON berantakan',
          builder: (_) => const JsonFormatterPage(),
        ),
        ToolEntry(
          icon: Icons.filter_alt_outlined,
          name: 'Regex Tester',
          desc: 'Test regex pattern, liat hasil match langsung',
          builder: (_) => const RegexTesterPage(),
        ),
        ToolEntry(
          icon: Icons.tag,
          name: 'Hash Generator',
          desc: 'Generate MD5, SHA1, SHA256, SHA512',
          builder: (_) => const HashGeneratorPage(),
        ),
        ToolEntry(
          icon: Icons.short_text,
          name: 'Word Counter',
          desc: 'Hitung kata, karakter, kalimat, paragraf',
          builder: (_) => const WordCounterPage(),
        ),
        ToolEntry(
          icon: Icons.text_fields,
          name: 'Text Case Converter',
          desc: 'Ubah format huruf sekali klik',
          builder: (_) => const TextCaseConverterPage(),
        ),
        ToolEntry(
          icon: Icons.article_outlined,
          name: 'Markdown Previewer',
          desc: 'Tulis & preview markdown live',
          builder: (_) => const MarkdownPreviewerPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Utilities',
      desc: 'Tools serbaguna sehari-hari',
      icon: Icons.build_outlined,
      tools: [
        ToolEntry(
          icon: Icons.record_voice_over_outlined,
          name: 'Text to Speech',
          desc: 'Ubah teks jadi suara',
          builder: (_) => const TtsPage(),
        ),
        ToolEntry(
          icon: Icons.wifi_tethering,
          name: 'IP Tracker',
          desc: 'Lacak info lengkap IP address (lokasi, ISP, dll)',
          builder: (_) => const IpTrackerPage(),
        ),
        ToolEntry(
          icon: Icons.warning_amber_rounded,
          name: 'Disaster Watch',
          desc: 'Pantau gempa (BMKG) & gunung api (MAGMA)',
          builder: (_) => const DisasterPage(),
        ),
        ToolEntry(
          icon: Icons.qr_code,
          name: 'QR Tool',
          desc: 'Generate & scan QR code',
          builder: (_) => const QrToolPage(),
        ),
        ToolEntry(
          icon: Icons.swap_horiz,
          name: 'Converter',
          desc: 'Konversi satuan & mata uang',
          builder: (_) => const ConverterPage(),
        ),
        ToolEntry(
          icon: Icons.wb_sunny_outlined,
          name: 'Weather',
          desc: 'Cuaca real-time lokasi kamu',
          builder: (_) => const WeatherPage(),
        ),
        ToolEntry(
          icon: Icons.folder_outlined,
          name: 'File Browser',
          desc: 'Liat & kelola file hasil download/simpanan app',
          builder: (_) => const FileBrowserPage(),
        ),
        ToolEntry(
          icon: Icons.calculate_outlined,
          name: 'Scientific Calculator',
          desc: 'Kalkulator ilmiah - trig, log, dll',
          builder: (_) => const ScientificCalculatorPage(),
        ),
        ToolEntry(
          icon: Icons.public,
          name: 'Timezone Converter',
          desc: 'Bandingin jam di berbagai kota',
          builder: (_) => const TimezoneConverterPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Security',
      desc: 'Privasi & kerahasiaan data',
      icon: Icons.shield_outlined,
      tools: [
        ToolEntry(
          icon: Icons.image_outlined,
          name: 'Steganography',
          desc: 'Sembunyiin/baca pesan rahasia di dalam gambar',
          builder: (_) => const SteganographyPage(),
        ),
        ToolEntry(
          icon: Icons.lock_outline,
          name: 'AES Text Encryptor',
          desc: 'Enkripsi/dekripsi teks pake password',
          builder: (_) => const AesTextPage(),
        ),
        ToolEntry(
          icon: Icons.password,
          name: 'Password Generator',
          desc: 'Generate password random yang kuat',
          builder: (_) => const PasswordGeneratorPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Productivity',
      desc: 'Catatan & tugas harian',
      icon: Icons.checklist_outlined,
      tools: [
        ToolEntry(
          icon: Icons.note_outlined,
          name: 'Notes',
          desc: 'Catatan cepat tersimpan lokal',
          builder: (_) => const NotesPage(),
        ),
        ToolEntry(
          icon: Icons.check_circle_outline,
          name: 'Todo List',
          desc: 'Checklist harian tersimpan lokal',
          builder: (_) => const TodoListPage(),
        ),
        ToolEntry(
          icon: Icons.content_paste,
          name: 'Clipboard History',
          desc: 'Histori teks yang pernah di-copy',
          builder: (_) => const ClipboardHistoryPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Media',
      desc: 'Olah gambar & warna',
      icon: Icons.image_outlined,
      tools: [
        ToolEntry(
          icon: Icons.compress,
          name: 'Image Compressor',
          desc: 'Kecilin ukuran & resize gambar, full lokal',
          builder: (_) => const ImageCompressorPage(),
        ),
        ToolEntry(
          icon: Icons.palette_outlined,
          name: 'Color Picker',
          desc: 'Pick warna & generate palet serasi',
          builder: (_) => const ColorPickerPage(),
        ),
      ],
    ),
  ];

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  List<ToolCategory> _categories = ToolsPage.builtInCategories;
  bool _hasWebTools = false;

  @override
  void initState() {
    super.initState();
    _loadMiniTools();
  }

  Future<void> _loadMiniTools() async {
    final miniTools = await MiniToolManifestService.fetch();
    if (!mounted || miniTools.isEmpty) return;

    // Gabungin ke kategori yang match namanya (case-insensitive), atau
    // bikin kategori baru kalau belum ada - jadi tools baru dari manifest
    // bisa nempel ke kategori manapun tanpa perlu update APK.
    final merged = ToolsPage.builtInCategories.map((c) => c).toList();
    for (final tool in miniTools) {
      final entry = ToolEntry(
        icon: tool.iconData,
        name: tool.name,
        desc: tool.desc,
        builder: (_) => MiniToolViewerPage(title: tool.name, url: tool.url),
      );
      final idx = merged.indexWhere((c) => c.title.toLowerCase() == tool.category.toLowerCase());
      if (idx >= 0) {
        merged[idx] = ToolCategory(
          title: merged[idx].title,
          desc: merged[idx].desc,
          icon: merged[idx].icon,
          tools: [...merged[idx].tools, entry],
        );
      } else {
        merged.add(ToolCategory(
          title: tool.category,
          desc: 'Tools tambahan',
          icon: Icons.cloud_download_outlined,
          tools: [entry],
        ));
      }
    }

    setState(() {
      _categories = merged;
      _hasWebTools = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Kyowi', accent: 'Tools', subtitle: 'Pilih kategori tools'),
        const SizedBox(height: 18),
        for (final category in _categories) ...[
          _categoryCard(context, category),
          const SizedBox(height: 10),
        ],
        if (_hasWebTools) ...[
          const SizedBox(height: 6),
          const Center(
            child: Text('☁ Sebagian tools dimuat otomatis dari server',
                style: TextStyle(color: AppColors.gray, fontSize: 9.5)),
          ),
        ],
      ],
    );
  }

  Widget _categoryCard(BuildContext context, ToolCategory category) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryToolsPage(category: category)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: AppColors.cyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('${category.tools.length} tools • ${category.desc}',
                      style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
