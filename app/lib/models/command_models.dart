class CommandCategory {
  final String id;
  final String name;
  final String nameEn;
  final String icon;
  final String color;

  CommandCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
  });

  factory CommandCategory.fromJson(Map<String, dynamic> json) => CommandCategory(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    nameEn: json['name_en'] ?? '',
    icon: json['icon'] ?? '',
    color: json['color'] ?? '#38bdf8',
  );
}

class CommandItem {
  final String id;
  final String title;
  final String tool;
  final String category;
  final String rawCommand;
  final String template;
  final List<String> variables;
  final String docTitle;
  final String docPath;

  CommandItem({
    required this.id,
    required this.title,
    required this.tool,
    required this.category,
    required this.rawCommand,
    required this.template,
    required this.variables,
    required this.docTitle,
    required this.docPath,
  });

  factory CommandItem.fromJson(Map<String, dynamic> json) => CommandItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    tool: json['tool'] ?? '',
    category: json['category'] ?? '',
    rawCommand: json['raw_command'] ?? '',
    template: json['template'] ?? '',
    variables: List<String>.from(json['variables'] ?? []),
    docTitle: json['doc_title'] ?? '',
    docPath: json['doc_path'] ?? '',
  );
}
