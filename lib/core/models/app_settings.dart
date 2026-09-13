/// Provider AI yang didukung buat fitur Chat with AI.
enum AiProvider { gemini, deepseek, blackbox, customRest }

/// Mesin pencari buat Browser - dipake pas user ngetik query (bukan URL)
/// di address bar.
enum SearchEngine { google, bing, duckduckgo, startpage, ecosia }

extension SearchEngineX on SearchEngine {
  String get label {
    switch (this) {
      case SearchEngine.google:
        return 'Google';
      case SearchEngine.bing:
        return 'Bing';
      case SearchEngine.duckduckgo:
        return 'DuckDuckGo';
      case SearchEngine.startpage:
        return 'Startpage';
      case SearchEngine.ecosia:
        return 'Ecosia';
    }
  }

  String urlFor(String query) {
    final q = Uri.encodeComponent(query);
    switch (this) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=$q';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=$q';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/?q=$q';
      case SearchEngine.startpage:
        return 'https://www.startpage.com/sp/search?query=$q';
      case SearchEngine.ecosia:
        return 'https://www.ecosia.org/search?q=$q';
    }
  }

  static SearchEngine fromKey(String? key) {
    return SearchEngine.values.firstWhere(
      (e) => e.name == key,
      orElse: () => SearchEngine.google,
    );
  }
}

extension AiProviderX on AiProvider {
  String get label {
    switch (this) {
      case AiProvider.gemini:
        return 'Gemini (Google)';
      case AiProvider.deepseek:
        return 'DeepSeek';
      case AiProvider.blackbox:
        return 'Blackbox AI';
      case AiProvider.customRest:
        return 'Custom REST API';
    }
  }

  static AiProvider fromKey(String? key) {
    return AiProvider.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AiProvider.gemini,
    );
  }
}

class AppSettings {
  String dashboardImageUrl;
  String webhookUrl;
  int requestTimeoutMs;
  bool notifPush;
  bool debugMode;
  bool autoSync;

  AiProvider aiProvider;
  String geminiApiKey;
  String geminiModel;
  String deepseekApiKey;
  String deepseekModel;
  String blackboxApiKey;
  String blackboxModel;

  // Custom REST API - dibuat fleksibel karena tiap API beda format.
  String customRestUrl;
  String customRestApiKey;
  String customRequestField;  // nama field buat kirim pesan user, default "message"
  String customResponseField; // path field buat ambil balasan, contoh: "choices.0.message.content"

  String githubToken;

  SearchEngine searchEngine;
  bool dataSaverMode;

  AppSettings({
    this.dashboardImageUrl = '',
    this.webhookUrl = '',
    this.requestTimeoutMs = 5000,
    this.notifPush = true,
    this.debugMode = false,
    this.autoSync = true,
    this.aiProvider = AiProvider.gemini,
    this.geminiApiKey = '',
    this.geminiModel = 'gemini-3.6-flash',
    this.deepseekApiKey = '',
    this.deepseekModel = 'deepseek-v4-flash',
    this.blackboxApiKey = '',
    this.blackboxModel = 'blackboxai/openai/gpt-5.5',
    this.customRestUrl = '',
    this.customRestApiKey = '',
    this.customRequestField = 'message',
    this.customResponseField = 'response',
    this.githubToken = '',
    this.searchEngine = SearchEngine.google,
    this.dataSaverMode = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      dashboardImageUrl: json['dashboardImageUrl'] ?? '',
      webhookUrl: json['webhookUrl'] ?? '',
      requestTimeoutMs: json['requestTimeoutMs'] ?? 5000,
      notifPush: json['notifPush'] ?? true,
      debugMode: json['debugMode'] ?? false,
      autoSync: json['autoSync'] ?? true,
      aiProvider: AiProviderX.fromKey(json['aiProvider']),
      geminiApiKey: json['geminiApiKey'] ?? '',
      geminiModel: (json['geminiModel'] as String?)?.trim().isNotEmpty == true
          ? json['geminiModel']
          : 'gemini-3.6-flash',
      deepseekApiKey: json['deepseekApiKey'] ?? '',
      deepseekModel: (json['deepseekModel'] as String?)?.trim().isNotEmpty == true
          ? json['deepseekModel']
          : 'deepseek-v4-flash',
      blackboxApiKey: json['blackboxApiKey'] ?? '',
      blackboxModel: (json['blackboxModel'] as String?)?.trim().isNotEmpty == true
          ? json['blackboxModel']
          : 'blackboxai/openai/gpt-5.5',
      customRestUrl: json['customRestUrl'] ?? '',
      customRestApiKey: json['customRestApiKey'] ?? '',
      customRequestField: (json['customRequestField'] as String?)?.trim().isNotEmpty == true
          ? json['customRequestField']
          : 'message',
      customResponseField: (json['customResponseField'] as String?)?.trim().isNotEmpty == true
          ? json['customResponseField']
          : 'response',
      githubToken: json['githubToken'] ?? '',
      searchEngine: SearchEngineX.fromKey(json['searchEngine']),
      dataSaverMode: json['dataSaverMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboardImageUrl': dashboardImageUrl,
      'webhookUrl': webhookUrl,
      'requestTimeoutMs': requestTimeoutMs,
      'notifPush': notifPush,
      'debugMode': debugMode,
      'autoSync': autoSync,
      'aiProvider': aiProvider.name,
      'geminiApiKey': geminiApiKey,
      'geminiModel': geminiModel,
      'deepseekApiKey': deepseekApiKey,
      'deepseekModel': deepseekModel,
      'blackboxApiKey': blackboxApiKey,
      'blackboxModel': blackboxModel,
      'customRestUrl': customRestUrl,
      'customRestApiKey': customRestApiKey,
      'customRequestField': customRequestField,
      'customResponseField': customResponseField,
      'githubToken': githubToken,
      'searchEngine': searchEngine.name,
      'dataSaverMode': dataSaverMode,
    };
  }
}
