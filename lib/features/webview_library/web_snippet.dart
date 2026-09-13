class WebSnippet {
  String id;
  String title;
  String desc;
  String html;
  int updatedAt;

  WebSnippet({
    required this.id,
    required this.title,
    required this.desc,
    required this.html,
    required this.updatedAt,
  });

  factory WebSnippet.fromJson(Map<String, dynamic> j) => WebSnippet(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        html: j['html'] as String? ?? '',
        updatedAt: j['updatedAt'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'desc': desc,
        'html': html,
        'updatedAt': updatedAt,
      };
}
