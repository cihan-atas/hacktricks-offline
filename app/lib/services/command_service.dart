import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/command_models.dart';

class CommandService extends ChangeNotifier {
  static final CommandService _instance = CommandService._internal();
  factory CommandService() => _instance;
  CommandService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<CommandCategory> _categories = [];
  List<CommandItem> _commands = [];

  List<CommandCategory> get categories => _categories;
  List<CommandItem> get commands => _commands;

  // Pentest Hedef & Dinleyici Parametreleri
  String _targetIp = '10.10.10.100';
  String _targetPort = '80';
  String _targetDomain = 'target.local';
  String _targetUrl = 'http://10.10.10.100';
  String _lhost = '10.10.14.5';
  String _lport = '4444';
  String _user = 'admin';
  String _password = 'Password123!';
  String _wordlist = '/usr/share/wordlists/dirb/common.txt';
  String _interface = 'eth0';

  String get targetIp => _targetIp;
  String get targetPort => _targetPort;
  String get targetDomain => _targetDomain;
  String get targetUrl => _targetUrl;
  String get lhost => _lhost;
  String get lport => _lport;
  String get user => _user;
  String get password => _password;
  String get wordlist => _wordlist;
  String get interface => _interface;

  // Filtreler
  String _selectedCategory = 'all';
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _targetIp = prefs.getString('cmd_target_ip') ?? _targetIp;
      _targetPort = prefs.getString('cmd_target_port') ?? _targetPort;
      _targetDomain = prefs.getString('cmd_target_domain') ?? _targetDomain;
      _targetUrl = prefs.getString('cmd_target_url') ?? _targetUrl;
      _lhost = prefs.getString('cmd_lhost') ?? _lhost;
      _lport = prefs.getString('cmd_lport') ?? _lport;
      _user = prefs.getString('cmd_user') ?? _user;
      _password = prefs.getString('cmd_password') ?? _password;
      _wordlist = prefs.getString('cmd_wordlist') ?? _wordlist;
      _interface = prefs.getString('cmd_interface') ?? _interface;

      final jsonStr = await rootBundle.loadString('assets/data/commands_catalog.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final rawCategories = data['categories'];
      if (rawCategories is Map<String, dynamic>) {
        _categories = rawCategories.values
            .map((c) => CommandCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      } else if (rawCategories is List<dynamic>) {
        _categories = rawCategories
            .map((c) => CommandCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      final rawCommands = (data['commands'] as List<dynamic>? ?? []);
      _commands = rawCommands.map((c) => CommandItem.fromJson(c as Map<String, dynamic>)).toList();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CommandService init error: $e');
    }
  }

  Future<void> updateParameters({
    String? targetIp,
    String? targetPort,
    String? targetDomain,
    String? targetUrl,
    String? lhost,
    String? lport,
    String? user,
    String? password,
    String? wordlist,
    String? interface,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (targetIp != null) {
      _targetIp = targetIp;
      await prefs.setString('cmd_target_ip', targetIp);
    }
    if (targetPort != null) {
      _targetPort = targetPort;
      await prefs.setString('cmd_target_port', targetPort);
    }
    if (targetDomain != null) {
      _targetDomain = targetDomain;
      await prefs.setString('cmd_target_domain', targetDomain);
    }
    if (targetUrl != null) {
      _targetUrl = targetUrl;
      await prefs.setString('cmd_target_url', targetUrl);
    }
    if (lhost != null) {
      _lhost = lhost;
      await prefs.setString('cmd_lhost', lhost);
    }
    if (lport != null) {
      _lport = lport;
      await prefs.setString('cmd_lport', lport);
    }
    if (user != null) {
      _user = user;
      await prefs.setString('cmd_user', user);
    }
    if (password != null) {
      _password = password;
      await prefs.setString('cmd_password', password);
    }
    if (wordlist != null) {
      _wordlist = wordlist;
      await prefs.setString('cmd_wordlist', wordlist);
    }
    if (interface != null) {
      _interface = interface;
      await prefs.setString('cmd_interface', interface);
    }

    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await updateParameters(
      targetIp: '10.10.10.100',
      targetPort: '80',
      targetDomain: 'target.local',
      targetUrl: 'http://10.10.10.100',
      lhost: '10.10.14.5',
      lport: '4444',
      user: 'admin',
      password: 'Password123!',
      wordlist: '/usr/share/wordlists/dirb/common.txt',
      interface: 'eth0',
    );
  }

  void setSelectedCategory(String catId) {
    _selectedCategory = catId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Canlı şablon derleme
  String compile(String template) {
    var result = template;
    result = result.replaceAll('{TARGET_IP}', _targetIp.trim());
    result = result.replaceAll('{TARGET_PORT}', _targetPort.trim());
    result = result.replaceAll('{TARGET_DOMAIN}', _targetDomain.trim());
    result = result.replaceAll('{DOMAIN}', _targetDomain.trim());
    result = result.replaceAll('{TARGET_URL}', _targetUrl.trim());
    result = result.replaceAll('{LHOST}', _lhost.trim());
    result = result.replaceAll('{LPORT}', _lport.trim());
    result = result.replaceAll('{USER}', _user.trim());
    result = result.replaceAll('{PASSWORD}', _password.trim());
    result = result.replaceAll('{WORDLIST}', _wordlist.trim());
    result = result.replaceAll('{INTERFACE}', _interface.trim());
    return result;
  }

  /// Belirli bir kategoride kaç komut olduğunu hesapla
  int countForCategory(String catId) {
    if (catId == 'all') return _commands.length;
    return _commands.where((c) => c.category == catId).length;
  }

  /// Filtrelenmiş komut listesi
  List<CommandItem> get filteredCommands {
    return _commands.where((cmd) {
      // Kategori filtresi
      if (_selectedCategory != 'all' && cmd.category != _selectedCategory) {
        return false;
      }
      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTool = cmd.tool.toLowerCase().contains(q);
        final matchTitle = cmd.title.toLowerCase().contains(q);
        final matchCmd = cmd.template.toLowerCase().contains(q);
        final matchDoc = cmd.docTitle.toLowerCase().contains(q);
        if (!matchTool && !matchTitle && !matchCmd && !matchDoc) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
