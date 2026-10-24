import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/command_models.dart';

class CommandService extends ChangeNotifier {
  static final CommandService _instance = CommandService._internal();
  factory CommandService() => _instance;
  CommandService._internal();

  static const String _targetContextKey = 'ht_target_context_v2';
  static const String _customCommandsKey = 'ht_custom_commands_v2';
  static const String _favoritesKey = 'ht_favorite_commands_v2';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  TargetContext _targetContext = const TargetContext();
  TargetContext get targetContext => _targetContext;

  String get targetIp => _targetContext.targetIp;
  String get targetPort => _targetContext.targetPort;
  String get targetDomain => _targetContext.targetDomain;
  String get targetUrl => _targetContext.targetUrl;
  String get lhost => _targetContext.lhost;
  String get lport => _targetContext.lport;
  String get user => _targetContext.user;
  String get password => _targetContext.pass;
  String get wordlist => _targetContext.wordlist;
  String get interface => _targetContext.interface;

  List<CommandCategory> _categories = [];
  List<CommandCategory> get categories => _categories;

  List<CommandItem> _allCommands = [];
  List<CommandItem> get commands => _allCommands;

  List<CommandItem> get customCommands =>
      _allCommands.where((c) => c.isUserCreated).toList();

  List<CommandItem> get favoriteCommands =>
      _allCommands.where((c) => c.isFavorite).toList();

  final Map<String, CommandFavorite> _favoritesMap = {};

  // Önbelleklenmiş Sayımlar (O(1) lookup için)
  final Map<String, int> _toolCounts = {};
  final Map<String, int> _categoryCounts = {};
  final Map<String, int> _platformCounts = {};
  final Map<String, int> _opsecCounts = {};

  // Önbelleklenmiş Filtre Çıktısı (Her frame'de 4500 öğeyi dönmemek için)
  List<CommandItem> _filteredCache = [];
  List<CommandItem> get filteredCommands => _filteredCache;

  // Şablon Derleme Önbelleği (Gereksiz string replace işlemlerini önler)
  final Map<String, String> _compiledCache = {};

  // Aktif Filtre Durumları
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedTool = 'all';
  String _selectedPlatform = 'all';
  OpsecTag _selectedOpsecTag = OpsecTag.all;
  CommandPillar _selectedPillar = CommandPillar.all;
  String _selectedFilterType = 'all'; // all, favorites, custom

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedTool => _selectedTool;
  String get selectedPlatform => _selectedPlatform;
  OpsecTag get selectedOpsecTag => _selectedOpsecTag;
  CommandPillar get selectedPillar => _selectedPillar;
  String get selectedFilterType => _selectedFilterType;

  int get activeFiltersCount {
    int c = 0;
    if (_selectedCategory != 'all') c++;
    if (_selectedTool != 'all') c++;
    if (_selectedPlatform != 'all') c++;
    if (_selectedOpsecTag != OpsecTag.all) c++;
    if (_selectedPillar != CommandPillar.all) c++;
    if (_selectedFilterType != 'all') c++;
    return c;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Hedef Bağlamını Yükle
      final ctxStr = prefs.getString(_targetContextKey);
      if (ctxStr != null) {
        try {
          _targetContext = TargetContext.fromJson(json.decode(ctxStr));
        } catch (_) {}
      }

      // 2. Favorileri Yükle
      final favsStr = prefs.getString(_favoritesKey);
      if (favsStr != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(favsStr);
          for (var entry in decoded.entries) {
            if (entry.value is Map<String, dynamic>) {
              _favoritesMap[entry.key] = CommandFavorite.fromJson(entry.value as Map<String, dynamic>);
            }
          }
        } catch (_) {}
      }

      // 3. Dahili Komut Kataloğunu Yükle
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
      final builtIn = rawCommands.map((c) => CommandItem.fromJson(c as Map<String, dynamic>)).toList();

      // 4. Özel Komutları Yükle
      List<CommandItem> userCmds = [];
      final customJson = prefs.getString(_customCommandsKey);
      if (customJson != null) {
        try {
          final List<dynamic> customList = json.decode(customJson);
          userCmds = customList.map((e) => CommandItem.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      // 5. Birleştir ve Favori Durumlarını İşle
      _allCommands = [...userCmds, ...builtIn];
      for (var cmd in _allCommands) {
        if (_favoritesMap.containsKey(cmd.id)) {
          final fav = _favoritesMap[cmd.id]!;
          cmd.isFavorite = true;
          cmd.userNote = fav.note;
        } else {
          cmd.isFavorite = false;
          cmd.userNote = null;
        }
      }

      _recomputeCounts();
      _applyFilter();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CommandService init error: $e');
    }
  }

  /// Tüm sayaçları tek bir geçişte (O(N)) hesaplar
  void _recomputeCounts() {
    _toolCounts.clear();
    _categoryCounts.clear();
    _platformCounts.clear();
    _opsecCounts.clear();

    for (final cmd in _allCommands) {
      // Araç sayımı
      final t = cmd.tool.toLowerCase();
      _toolCounts[t] = (_toolCounts[t] ?? 0) + 1;

      // Impacket & NetExec ailesi
      if (t.contains('impacket') || t.contains('secretsdump') || t.contains('psexec') ||
          t.contains('wmiexec') || t.contains('smbexec') || t.contains('ntlmrelayx')) {
        _toolCounts['impacket'] = (_toolCounts['impacket'] ?? 0) + 1;
      }
      if (t == 'netexec' || t == 'nxc' || t == 'crackmapexec') {
        _toolCounts['netexec'] = (_toolCounts['netexec'] ?? 0) + 1;
      }

      // Kategori sayımı
      _categoryCounts[cmd.category] = (_categoryCounts[cmd.category] ?? 0) + 1;

      // Platform sayımı
      _platformCounts[cmd.platform] = (_platformCounts[cmd.platform] ?? 0) + 1;

      // OPSEC sayımı
      _opsecCounts[cmd.opsec] = (_opsecCounts[cmd.opsec] ?? 0) + 1;
    }
  }

  // --- HEDEF BAĞLAMI YÖNETİMİ ---
  Future<void> updateTargetContext(TargetContext newCtx) async {
    _targetContext = newCtx;
    _compiledCache.clear(); // Parametreler değişince derleme önbelleğini sıfırla
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetContextKey, json.encode(newCtx.toJson()));
    notifyListeners();
  }

  Future<void> updateParameters({
    String? targetIp,
    String? targetPort,
    String? targetDomain,
    String? targetUrl,
    String? netbios,
    String? dcIp,
    String? user,
    String? password,
    String? hash,
    String? lhost,
    String? lport,
    String? wordlist,
    String? interface,
  }) async {
    final updated = _targetContext.copyWith(
      targetIp: targetIp,
      targetPort: targetPort,
      targetDomain: targetDomain,
      targetUrl: targetUrl,
      netbios: netbios,
      dcIp: dcIp,
      user: user,
      pass: password,
      hash: hash,
      lhost: lhost,
      lport: lport,
      wordlist: wordlist,
      interface: interface,
    );
    await updateTargetContext(updated);
  }

  Future<void> resetToDefaults() async {
    await updateTargetContext(const TargetContext());
  }

  // --- FAVORİ YÖNETİMİ ---
  Future<void> toggleFavorite(CommandItem cmd, {String? note}) async {
    if (cmd.isFavorite) {
      await removeFavorite(cmd.id);
    } else {
      await saveFavorite(cmd.id, note: note ?? '');
    }
  }

  Future<void> saveFavorite(String cmdId, {String note = '', String category = 'Genel'}) async {
    final fav = CommandFavorite(
      commandId: cmdId,
      note: note.trim(),
      category: category.trim(),
    );
    _favoritesMap[cmdId] = fav;

    final idx = _allCommands.indexWhere((c) => c.id == cmdId);
    if (idx >= 0) {
      _allCommands[idx].isFavorite = true;
      _allCommands[idx].userNote = note.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_favoritesMap.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_favoritesKey, jsonStr);
    _applyFilter();
    notifyListeners();
  }

  Future<void> removeFavorite(String cmdId) async {
    _favoritesMap.remove(cmdId);

    final idx = _allCommands.indexWhere((c) => c.id == cmdId);
    if (idx >= 0) {
      _allCommands[idx].isFavorite = false;
      _allCommands[idx].userNote = null;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_favoritesMap.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_favoritesKey, jsonStr);
    _applyFilter();
    notifyListeners();
  }

  // --- KULLANICI ÖZEL KOMUTLARI ---
  Future<void> saveCustomCommand(CommandItem cmd) async {
    final idx = _allCommands.indexWhere((c) => c.id == cmd.id);
    if (idx >= 0) {
      _allCommands[idx] = cmd;
    } else {
      _allCommands.insert(0, cmd);
    }

    final customs = customCommands;
    final prefs = await SharedPreferences.getInstance();
    final data = customs.map((c) => c.toJson()).toList();
    await prefs.setString(_customCommandsKey, json.encode(data));
    _recomputeCounts();
    _applyFilter();
    notifyListeners();
  }

  Future<void> deleteCustomCommand(String id) async {
    _allCommands.removeWhere((c) => c.id == id && c.isUserCreated);
    final customs = customCommands;
    final prefs = await SharedPreferences.getInstance();
    final data = customs.map((c) => c.toJson()).toList();
    await prefs.setString(_customCommandsKey, json.encode(data));
    _recomputeCounts();
    _applyFilter();
    notifyListeners();
  }

  // --- FİLTRELEME & CANLI ARAMA (OPTİMİZE EDİLMİŞ) ---
  void setSearchQuery(String q) {
    if (_searchQuery == q) return;
    _searchQuery = q;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedCategory(String cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedTool(String tool) {
    if (_selectedTool == tool) return;
    _selectedTool = tool;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedPlatform(String plat) {
    if (_selectedPlatform == plat) return;
    _selectedPlatform = plat;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedOpsecTag(OpsecTag tag) {
    if (_selectedOpsecTag == tag) return;
    _selectedOpsecTag = tag;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedPillar(CommandPillar pillar) {
    if (_selectedPillar == pillar) return;
    _selectedPillar = pillar;
    _applyFilter();
    notifyListeners();
  }

  void setSelectedFilterType(String type) {
    if (_selectedFilterType == type) return;
    _selectedFilterType = type;
    _applyFilter();
    notifyListeners();
  }

  void resetAllFilters() {
    _searchQuery = '';
    _selectedCategory = 'all';
    _selectedTool = 'all';
    _selectedPlatform = 'all';
    _selectedOpsecTag = OpsecTag.all;
    _selectedPillar = CommandPillar.all;
    _selectedFilterType = 'all';
    _applyFilter();
    notifyListeners();
  }

  /// Filtreleri tek seferde uygulayıp önbellekler (Sıfır Donma Garantisi)
  void _applyFilter() {
    final q = _searchQuery.toLowerCase().trim();
    final toolLow = _selectedTool.toLowerCase();

    _filteredCache = _allCommands.where((cmd) {
      // 1. Tip Filtresi
      if (_selectedFilterType == 'favorites' && !cmd.isFavorite) return false;
      if (_selectedFilterType == 'custom' && !cmd.isUserCreated) return false;

      // 2. Kategori Filtresi
      if (_selectedCategory != 'all' && cmd.category != _selectedCategory) return false;

      // 3. Araç Filtresi
      if (_selectedTool != 'all') {
        if (toolLow == 'impacket') {
          final t = cmd.tool.toLowerCase();
          if (!t.contains('impacket') && !t.contains('secretsdump') && !t.contains('psexec') &&
              !t.contains('wmiexec') && !t.contains('smbexec') && !t.contains('ntlmrelayx')) {
            return false;
          }
        } else if (toolLow == 'netexec') {
          final t = cmd.tool.toLowerCase();
          if (t != 'netexec' && t != 'nxc' && t != 'crackmapexec') return false;
        } else if (toolLow == 'cloud') {
          if (cmd.category != 'cloud') return false;
        } else if (cmd.tool.toLowerCase() != toolLow) {
          return false;
        }
      }

      // 4. Platform Filtresi
      if (_selectedPlatform != 'all' && cmd.platform != _selectedPlatform) return false;

      // 5. OPSEC Filtresi
      if (_selectedOpsecTag != OpsecTag.all && cmd.opsec != _selectedOpsecTag.id) return false;

      // 6. Pillar Filtresi
      if (_selectedPillar != CommandPillar.all && cmd.pillar != _selectedPillar.id) return false;

      // 7. Arama Sorgusu (Önceden birleştirilmiş ve lowercased indeks üzerinden kontrol)
      if (q.isNotEmpty) {
        if (!cmd.searchText.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  // --- MEMOIZED CANLI ŞABLON DERLEME ---
  String compile(String template, [TargetContext? ctx]) {
    final c = ctx ?? _targetContext;
    // Cache anahtarı
    final cacheKey = '${template.hashCode}_${c.targetIp}_${c.targetPort}_${c.lhost}_${c.lport}_${c.user}';
    final existing = _compiledCache[cacheKey];
    if (existing != null) return existing;

    var result = template;

    // {{...}} yer tutucuları
    result = result.replaceAll('{{target_ip}}', c.targetIp.trim());
    result = result.replaceAll('{{target_url}}', c.targetUrl.trim());
    result = result.replaceAll('{{target_host}}', c.targetDomain.trim());
    result = result.replaceAll('{{domain}}', c.targetDomain.trim());
    result = result.replaceAll('{{netbios}}', c.netbios.trim());
    result = result.replaceAll('{{dc_ip}}', c.dcIp.trim());
    result = result.replaceAll('{{port}}', c.targetPort.trim());
    result = result.replaceAll('{{user}}', c.user.trim());
    result = result.replaceAll('{{pass}}', c.pass.trim());
    result = result.replaceAll('{{hash}}', c.hash.trim());
    result = result.replaceAll('{{lhost}}', c.lhost.trim());
    result = result.replaceAll('{{lport}}', c.lport.trim());
    result = result.replaceAll('{{wordlist}}', c.wordlist.trim());
    result = result.replaceAll('{{interface}}', c.interface.trim());

    // {...} büyük harfli yer tutucuları
    result = result.replaceAll('{TARGET_IP}', c.targetIp.trim());
    result = result.replaceAll('{TARGET_PORT}', c.targetPort.trim());
    result = result.replaceAll('{PORT}', c.targetPort.trim());
    result = result.replaceAll('{TARGET_DOMAIN}', c.targetDomain.trim());
    result = result.replaceAll('{DOMAIN}', c.targetDomain.trim());
    result = result.replaceAll('{TARGET_URL}', c.targetUrl.trim());
    result = result.replaceAll('{NETBIOS}', c.netbios.trim());
    result = result.replaceAll('{DC_IP}', c.dcIp.trim());
    result = result.replaceAll('{USER}', c.user.trim());
    result = result.replaceAll('{PASSWORD}', c.pass.trim());
    result = result.replaceAll('{PASS}', c.pass.trim());
    result = result.replaceAll('{HASH}', c.hash.trim());
    result = result.replaceAll('{LHOST}', c.lhost.trim());
    result = result.replaceAll('{LPORT}', c.lport.trim());
    result = result.replaceAll('{WORDLIST}', c.wordlist.trim());
    result = result.replaceAll('{INTERFACE}', c.interface.trim());

    _compiledCache[cacheKey] = result;
    return result;
  }

  // --- O(1) SAYAÇ SORGULARI ---
  int countForCategory(String catId) {
    if (catId == 'all') return _allCommands.length;
    return _categoryCounts[catId] ?? 0;
  }

  int countForTool(String toolName) {
    if (toolName == 'all') return _allCommands.length;
    return _toolCounts[toolName.toLowerCase()] ?? 0;
  }

  int countForPlatform(String plat) {
    if (plat == 'all') return _allCommands.length;
    return _platformCounts[plat] ?? 0;
  }

  int countForOpsec(OpsecTag tag) {
    if (tag == OpsecTag.all) return _allCommands.length;
    return _opsecCounts[tag.id] ?? 0;
  }
}
