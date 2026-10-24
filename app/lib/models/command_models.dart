import 'package:flutter/material.dart';

/// OPSEC ve Davranış Etiketleri
enum OpsecTag {
  all(id: 'all', label: 'Tüm OPSEC', icon: Icons.all_inclusive, colorHex: 0xFFF59E0B),
  stealth(id: 'stealth', label: '🟢 EDR Sessiz (Stealth)', icon: Icons.visibility_off, colorHex: 0xFF10B981),
  noisy(id: 'noisy', label: '🔴 Gürültülü (Noisy)', icon: Icons.volume_up, colorHex: 0xFFEF4444),
  safe(id: 'safe', label: '🛡️ Güvenli / Pasif', icon: Icons.shield, colorHex: 0xFF3B82F6),
  offline(id: 'offline', label: '⛏️ Çevrimdışı Kırma', icon: Icons.lock_open, colorHex: 0xFF8B5CF6),
  lateral(id: 'lateral', label: '⚡ Yanal Hareket', icon: Icons.swap_horiz, colorHex: 0xFFEC4899);

  final String id;
  final String label;
  final IconData icon;
  final int colorHex;

  const OpsecTag({
    required this.id,
    required this.label,
    required this.icon,
    required this.colorHex,
  });

  Color get color => Color(colorHex);
}

/// HackTricks Vault Ana Sütunları (Pillars)
enum CommandPillar {
  all(id: 'all', label: 'Tümü', icon: Icons.all_inclusive, colorHex: 0xFFF59E0B),
  redTeam(id: 'red', label: '🔴 Red Team', icon: Icons.security, colorHex: 0xFFEF4444),
  blueTeam(id: 'blue', label: '🔵 Blue Team', icon: Icons.shield, colorHex: 0xFF3B82F6);

  final String id;
  final String label;
  final IconData icon;
  final int colorHex;

  const CommandPillar({
    required this.id,
    required this.label,
    required this.icon,
    required this.colorHex,
  });

  Color get color => Color(colorHex);
}

/// Pentest Hedef ve Dinleyici Bağlamı (Target Context)
class TargetContext {
  final String targetIp;
  final String targetPort;
  final String targetUrl;
  final String targetDomain;
  final String netbios;
  final String dcIp;
  final String user;
  final String pass;
  final String hash;
  final String lhost;
  final String lport;
  final String wordlist;
  final String interface;

  const TargetContext({
    this.targetIp = '10.10.10.100',
    this.targetPort = '80',
    this.targetUrl = 'http://10.10.10.100',
    this.targetDomain = 'target.local',
    this.netbios = 'TARGET',
    this.dcIp = '10.10.10.10',
    this.user = 'admin',
    this.pass = 'Password123!',
    this.hash = 'e19ccf7504d36cedc34e212d4e6547e0',
    this.lhost = '10.10.14.5',
    this.lport = '4444',
    this.wordlist = '/usr/share/wordlists/dirb/common.txt',
    this.interface = 'eth0',
  });

  TargetContext copyWith({
    String? targetIp,
    String? targetPort,
    String? targetUrl,
    String? targetDomain,
    String? netbios,
    String? dcIp,
    String? user,
    String? pass,
    String? hash,
    String? lhost,
    String? lport,
    String? wordlist,
    String? interface,
  }) {
    return TargetContext(
      targetIp: targetIp ?? this.targetIp,
      targetPort: targetPort ?? this.targetPort,
      targetUrl: targetUrl ?? this.targetUrl,
      targetDomain: targetDomain ?? this.targetDomain,
      netbios: netbios ?? this.netbios,
      dcIp: dcIp ?? this.dcIp,
      user: user ?? this.user,
      pass: pass ?? this.pass,
      hash: hash ?? this.hash,
      lhost: lhost ?? this.lhost,
      lport: lport ?? this.lport,
      wordlist: wordlist ?? this.wordlist,
      interface: interface ?? this.interface,
    );
  }

  Map<String, dynamic> toJson() => {
    'targetIp': targetIp,
    'targetPort': targetPort,
    'targetUrl': targetUrl,
    'targetDomain': targetDomain,
    'netbios': netbios,
    'dcIp': dcIp,
    'user': user,
    'pass': pass,
    'hash': hash,
    'lhost': lhost,
    'lport': lport,
    'wordlist': wordlist,
    'interface': interface,
  };

  factory TargetContext.fromJson(Map<String, dynamic> json) => TargetContext(
    targetIp: json['targetIp'] ?? '10.10.10.100',
    targetPort: json['targetPort'] ?? '80',
    targetUrl: json['targetUrl'] ?? 'http://10.10.10.100',
    targetDomain: json['targetDomain'] ?? 'target.local',
    netbios: json['netbios'] ?? 'TARGET',
    dcIp: json['dcIp'] ?? '10.10.10.10',
    user: json['user'] ?? 'admin',
    pass: json['pass'] ?? 'Password123!',
    hash: json['hash'] ?? 'e19ccf7504d36cedc34e212d4e6547e0',
    lhost: json['lhost'] ?? '10.10.14.5',
    lport: json['lport'] ?? '4444',
    wordlist: json['wordlist'] ?? '/usr/share/wordlists/dirb/common.txt',
    interface: json['interface'] ?? 'eth0',
  );
}

/// Favori Komut ve Kullanıcı Notu Modeli
class CommandFavorite {
  final String commandId;
  final String note;
  final String category;
  final DateTime addedAt;

  CommandFavorite({
    required this.commandId,
    this.note = '',
    this.category = 'Genel',
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'commandId': commandId,
    'note': note,
    'category': category,
    'addedAt': addedAt.toIso8601String(),
  };

  factory CommandFavorite.fromJson(Map<String, dynamic> json) => CommandFavorite(
    commandId: json['commandId'] as String? ?? '',
    note: json['note'] as String? ?? '',
    category: json['category'] as String? ?? 'Genel',
    addedAt: json['addedAt'] != null
        ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_en': nameEn,
    'icon': icon,
    'color': color,
  };
}

class CommandItem {
  final String id;
  final String title;
  final String tool;
  final String category;
  final String platform;
  final String pillar;
  final String opsec;
  final String rawCommand;
  final String template;
  final List<String> variables;
  final String docTitle;
  final String docPath;
  final String lang;
  bool isFavorite;
  String? userNote;
  final bool isUserCreated;
  final String searchText;

  CommandItem({
    required this.id,
    required this.title,
    required this.tool,
    required this.category,
    this.platform = 'Linux CLI',
    this.pillar = 'red',
    this.opsec = 'noisy',
    required this.rawCommand,
    required this.template,
    required this.variables,
    required this.docTitle,
    required this.docPath,
    this.lang = 'en',
    this.isFavorite = false,
    this.userNote,
    this.isUserCreated = false,
  }) : searchText = '$tool $title $template $docTitle ${userNote ?? ""}'.toLowerCase();

  factory CommandItem.fromJson(Map<String, dynamic> json) => CommandItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    tool: json['tool'] ?? '',
    category: json['category'] ?? '',
    platform: json['platform'] ?? 'Linux CLI',
    pillar: json['pillar'] ?? 'red',
    opsec: json['opsec'] ?? 'noisy',
    rawCommand: json['raw_command'] ?? '',
    template: json['template'] ?? '',
    variables: List<String>.from(json['variables'] ?? []),
    docTitle: json['doc_title'] ?? '',
    docPath: json['doc_path'] ?? '',
    lang: json['lang'] ?? 'en',
    isFavorite: json['isFavorite'] == true,
    userNote: json['userNote'],
    isUserCreated: json['isUserCreated'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'tool': tool,
    'category': category,
    'platform': platform,
    'pillar': pillar,
    'opsec': opsec,
    'raw_command': rawCommand,
    'template': template,
    'variables': variables,
    'doc_title': docTitle,
    'doc_path': docPath,
    'lang': lang,
    'isFavorite': isFavorite,
    'userNote': userNote,
    'isUserCreated': isUserCreated,
  };
}
