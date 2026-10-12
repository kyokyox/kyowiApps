class ChecklistItem {
  String id;
  String text;
  bool done;

  ChecklistItem({required this.id, required this.text, this.done = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};
}

class ChecklistGroup {
  String id;
  String name;
  List<ChecklistItem> items;
  bool active;
  String? lastResetDate; // format: 'yyyy-MM-dd', null = belum pernah di-reset

  ChecklistGroup({
    required this.id,
    required this.name,
    required this.items,
    this.active = false,
    this.lastResetDate,
  });

  factory ChecklistGroup.fromJson(Map<String, dynamic> j) => ChecklistGroup(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        active: j['active'] as bool? ?? false,
        lastResetDate: j['lastResetDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'active': active,
        'lastResetDate': lastResetDate,
      };

  int get doneCount => items.where((i) => i.done).length;
}
