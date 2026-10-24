import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/command_models.dart';
import '../services/command_service.dart';
import '../services/content_service.dart';
import '../services/scratchpad_service.dart';
import '../theme/app_theme.dart';
import 'article_screen.dart';

class CommandGeneratorScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final String? initialTool;
  final String? initialCategory;
  final OpsecTag? initialOpsecTag;

  const CommandGeneratorScreen({
    super.key,
    this.initialSearchQuery,
    this.initialTool,
    this.initialCategory,
    this.initialOpsecTag,
  });

  @override
  State<CommandGeneratorScreen> createState() => _CommandGeneratorScreenState();
}

class _PopularTool {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _PopularTool({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _CommandGeneratorScreenState extends State<CommandGeneratorScreen> {
  final CommandService _service = CommandService();
  final ContentService _contentService = ContentService();
  final ScratchpadService _scratchpadService = ScratchpadService();

  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  Timer? _searchDebounceTimer;

  bool _isConfigExpanded = false;
  bool _isFiltersExpanded = false;
  bool _showBackToTop = false;
  int _displayLimit = 50;

  // Hedef Bağlamı Controller'ları
  late TextEditingController _targetIpCtrl;
  late TextEditingController _targetPortCtrl;
  late TextEditingController _targetDomainCtrl;
  late TextEditingController _targetUrlCtrl;
  late TextEditingController _netbiosCtrl;
  late TextEditingController _dcIpCtrl;
  late TextEditingController _lhostCtrl;
  late TextEditingController _lportCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _hashCtrl;
  late TextEditingController _wordlistCtrl;

  // Popüler Araç Aileleri
  static const List<_PopularTool> popularTools = [
    _PopularTool(key: 'nmap', label: 'Nmap', icon: Icons.radar, color: Color(0xFF38BDF8)),
    _PopularTool(key: 'ffuf', label: 'FFUF', icon: Icons.language, color: Color(0xFFF59E0B)),
    _PopularTool(key: 'sqlmap', label: 'SQLMap', icon: Icons.storage, color: Color(0xFFEF4444)),
    _PopularTool(key: 'impacket', label: 'Impacket', icon: Icons.security, color: Color(0xFF8B5CF6)),
    _PopularTool(key: 'netexec', label: 'NetExec / CME', icon: Icons.terminal, color: Color(0xFF10B981)),
    _PopularTool(key: 'mimikatz', label: 'Mimikatz', icon: Icons.key, color: Color(0xFFEC4899)),
    _PopularTool(key: 'bloodhound', label: 'BloodHound', icon: Icons.hub, color: Color(0xFF6366F1)),
    _PopularTool(key: 'certipy', label: 'Certipy', icon: Icons.badge, color: Color(0xFF06B6D4)),
    _PopularTool(key: 'rubeus', label: 'Rubeus', icon: Icons.verified_user, color: Color(0xFFF97316)),
    _PopularTool(key: 'chisel', label: 'Chisel', icon: Icons.swap_horiz, color: Color(0xFF14B8A6)),
    _PopularTool(key: 'linpeas', label: 'LinPEAS', icon: Icons.arrow_upward, color: Color(0xFFEAB308)),
    _PopularTool(key: 'winpeas', label: 'WinPEAS', icon: Icons.desktop_windows, color: Color(0xFF3B82F6)),
    _PopularTool(key: 'hashcat', label: 'Hashcat', icon: Icons.lock_open, color: Color(0xFFF43F5E)),
    _PopularTool(key: 'hydra', label: 'Hydra', icon: Icons.lock_reset, color: Color(0xFFA855F7)),
    _PopularTool(key: 'responder', label: 'Responder', icon: Icons.hearing, color: Color(0xFF0EA5E9)),
    _PopularTool(key: 'docker', label: 'Docker / K8s', icon: Icons.layers, color: Color(0xFF22C55E)),
    _PopularTool(key: 'nuclei', label: 'Nuclei', icon: Icons.bug_report, color: Color(0xFFFB923C)),
    _PopularTool(key: 'cloud', label: 'AWS / Cloud', icon: Icons.cloud, color: Color(0xFF38BDF8)),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery ?? _service.searchQuery);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final show = _scrollController.hasClients && _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() => _showBackToTop = show);
      }
      // Akıcı Sanal Sayfalama (Infinite Scroll Pagination)
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
        if (_displayLimit < _service.filteredCommands.length) {
          setState(() {
            _displayLimit = math.min(_displayLimit + 40, _service.filteredCommands.length);
          });
        }
      }
    });

    if (widget.initialTool != null) _service.setSelectedTool(widget.initialTool!);
    if (widget.initialCategory != null) _service.setSelectedCategory(widget.initialCategory!);
    if (widget.initialOpsecTag != null) _service.setSelectedOpsecTag(widget.initialOpsecTag!);

    _initControllers();
  }

  void _initControllers() {
    final ctx = _service.targetContext;
    _targetIpCtrl = TextEditingController(text: ctx.targetIp);
    _targetPortCtrl = TextEditingController(text: ctx.targetPort);
    _targetDomainCtrl = TextEditingController(text: ctx.targetDomain);
    _targetUrlCtrl = TextEditingController(text: ctx.targetUrl);
    _netbiosCtrl = TextEditingController(text: ctx.netbios);
    _dcIpCtrl = TextEditingController(text: ctx.dcIp);
    _lhostCtrl = TextEditingController(text: ctx.lhost);
    _lportCtrl = TextEditingController(text: ctx.lport);
    _userCtrl = TextEditingController(text: ctx.user);
    _passCtrl = TextEditingController(text: ctx.pass);
    _hashCtrl = TextEditingController(text: ctx.hash);
    _wordlistCtrl = TextEditingController(text: ctx.wordlist);
  }

  void _syncControllersWithContext() {
    final ctx = _service.targetContext;
    _targetIpCtrl.text = ctx.targetIp;
    _targetPortCtrl.text = ctx.targetPort;
    _targetDomainCtrl.text = ctx.targetDomain;
    _targetUrlCtrl.text = ctx.targetUrl;
    _netbiosCtrl.text = ctx.netbios;
    _dcIpCtrl.text = ctx.dcIp;
    _lhostCtrl.text = ctx.lhost;
    _lportCtrl.text = ctx.lport;
    _userCtrl.text = ctx.user;
    _passCtrl.text = ctx.pass;
    _hashCtrl.text = ctx.hash;
    _wordlistCtrl.text = ctx.wordlist;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _targetIpCtrl.dispose();
    _targetPortCtrl.dispose();
    _targetDomainCtrl.dispose();
    _targetUrlCtrl.dispose();
    _netbiosCtrl.dispose();
    _dcIpCtrl.dispose();
    _lhostCtrl.dispose();
    _lportCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _hashCtrl.dispose();
    _wordlistCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _displayLimit = 50;
      });
      _service.setSearchQuery(val);
    });
  }

  Color _parseHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.redTeam;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.sysAdmin, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label panoya kopyalandı!',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.sysAdmin, width: 1),
        ),
      ),
    );
  }

  void _addToScratchpad(CommandItem cmd, String compiledCmd) {
    final note = '### ${cmd.tool.toUpperCase()}: ${cmd.title}\n```bash\n$compiledCmd\n```\n';
    _scratchpadService.appendContent(note, title: '${cmd.tool.toUpperCase()}: ${cmd.title}');
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.note_alt, color: AppTheme.blueTeam, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text('Komut Not Defterine eklendi!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.blueTeam, width: 1),
        ),
      ),
    );
  }

  void _openFavoriteDialog(CommandItem cmd) {
    final noteController = TextEditingController(text: cmd.userNote ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            Icon(
              cmd.isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(cmd.isFavorite ? 'Favoriyi Düzenle' : 'Favorilere Ekle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cmd.title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Özel not veya etiket (Örn: HTB Forest kutusunda çalıştı)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (cmd.isFavorite)
            TextButton(
              onPressed: () {
                _service.removeFavorite(cmd.id);
                Navigator.pop(ctx);
              },
              child: const Text('Favorilerden Çıkar', style: TextStyle(color: AppTheme.redTeam)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _service.saveFavorite(cmd.id, note: noteController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redTeam),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _openAddCustomCommandDialog() {
    final toolCtrl = TextEditingController(text: 'custom');
    final titleCtrl = TextEditingController();
    final cmdCtrl = TextEditingController();
    String selectedCat = 'recon';
    String selectedPlat = 'Linux CLI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.sysAdmin, size: 24),
              SizedBox(width: 10),
              Text('Özel Komut Ekle'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: toolCtrl,
                  decoration: const InputDecoration(labelText: 'Araç Adı (nmap, curl, vb.)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Komut Açıklaması / Senaryo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                  dropdownColor: AppTheme.bgCard,
                  items: _service.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDlgState(() => selectedCat = v ?? 'recon'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPlat,
                  decoration: const InputDecoration(labelText: 'Platform', border: OutlineInputBorder()),
                  dropdownColor: AppTheme.bgCard,
                  items: const [
                    DropdownMenuItem(value: 'Linux CLI', child: Text('Linux CLI')),
                    DropdownMenuItem(value: 'PowerShell', child: Text('PowerShell')),
                    DropdownMenuItem(value: 'Windows CMD / Binary', child: Text('Windows CMD')),
                    DropdownMenuItem(value: 'Linux / Cross-Platform', child: Text('Cross-Platform')),
                  ],
                  onChanged: (v) => setDlgState(() => selectedPlat = v ?? 'Linux CLI'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cmdCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Komut Şablonu (örn: nmap -sC -sV {{target_ip}})',
                    hintText: '{{target_ip}}, {{lhost}}, {{lport}}, {{user}}...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (cmdCtrl.text.trim().isEmpty) return;
                final custom = CommandItem(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim().isEmpty ? 'Özel Komut' : titleCtrl.text.trim(),
                  tool: toolCtrl.text.trim().toLowerCase(),
                  category: selectedCat,
                  platform: selectedPlat,
                  rawCommand: cmdCtrl.text.trim(),
                  template: cmdCtrl.text.trim(),
                  variables: [],
                  docTitle: 'Kullanıcı Özel Komutu',
                  docPath: '',
                  isUserCreated: true,
                );
                _service.saveCustomCommand(custom);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redTeam),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuickEditParamDialog(String paramName, String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Parametre Düzenle: $paramName'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textPrimary),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: currentValue,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (paramName == 'TARGET_IP') _service.updateParameters(targetIp: val);
              if (paramName == 'PORT' || paramName == 'TARGET_PORT') _service.updateParameters(targetPort: val);
              if (paramName == 'TARGET_URL') _service.updateParameters(targetUrl: val);
              if (paramName == 'DOMAIN' || paramName == 'TARGET_DOMAIN') _service.updateParameters(targetDomain: val);
              if (paramName == 'LHOST') _service.updateParameters(lhost: val);
              if (paramName == 'LPORT') _service.updateParameters(lport: val);
              if (paramName == 'USER') _service.updateParameters(user: val);
              if (paramName == 'PASSWORD' || paramName == 'PASS') _service.updateParameters(password: val);
              if (paramName == 'WORDLIST') _service.updateParameters(wordlist: val);
              _syncControllersWithContext();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redTeam),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = _contentService.currentLanguage == 'tr';

    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final filtered = _service.filteredCommands;
        final totalCount = _service.commands.length;
        final favCount = _service.favoriteCommands.length;
        final customCount = _service.customCommands.length;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.redTeam.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.redTeam, width: 1.5),
                  ),
                  child: const Icon(Icons.terminal, size: 20, color: AppTheme.redTeam),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Arsenal Cephaneliği' : 'Command Arsenal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      '$totalCount ${isTr ? "Canlı Komut" : "Live Commands"} (${filtered.length} ${isTr ? "listeleniyor" : "filtered"})',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Gelişmiş Filtreler Aç/Kapa Butonu
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isFiltersExpanded ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: _isFiltersExpanded || _service.activeFiltersCount > 0
                          ? AppTheme.redTeam
                          : AppTheme.textPrimary,
                    ),
                    tooltip: isTr ? 'Filtreleri Genişlet' : 'Toggle Filters',
                    onPressed: () {
                      setState(() {
                        _isFiltersExpanded = !_isFiltersExpanded;
                      });
                    },
                  ),
                  if (_service.activeFiltersCount > 0)
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.redTeam,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_service.activeFiltersCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              // Hedef Bağlamı Aç/Kapa Butonu
              IconButton(
                icon: Icon(
                  _isConfigExpanded ? Icons.tune : Icons.tune_outlined,
                  color: _isConfigExpanded ? AppTheme.toolsAmber : AppTheme.textPrimary,
                ),
                tooltip: isTr ? 'Hedef & Dinleyici Ayarları' : 'Target & Listener Settings',
                onPressed: () {
                  setState(() {
                    _isConfigExpanded = !_isConfigExpanded;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Hedef ve Dinleyici Parametreleri Kartı
              _buildTargetContextCard(isTr),

              // 2. Arama Çubuğu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isTr
                        ? '4.500+ komut, araç (nmap, ffuf, chisel, impacket) veya başlık ara...'
                        : 'Search 4,500+ commands, tools, or techniques...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _service.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.redTeam, width: 1.5),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              // 3. Popüler Araç Aileleri Çipleri (Yatay Kaydırılabilir)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildPopularToolChip(
                      key: 'all',
                      label: isTr ? 'Tüm Araçlar' : 'All Tools',
                      count: _service.commands.length,
                      icon: Icons.apps,
                      color: AppTheme.redTeam,
                      isSelected: _service.selectedTool == 'all',
                    ),
                    ...popularTools.map((t) {
                      final count = _service.countForTool(t.key);
                      final isSelected = _service.selectedTool == t.key;
                      return _buildPopularToolChip(
                        key: t.key,
                        label: t.label,
                        count: count,
                        icon: t.icon,
                        color: t.color,
                        isSelected: isSelected,
                      );
                    }),
                  ],
                ),
              ),

              // 4. Gelişmiş Filtre Çekmecesi (Platform, Kategori, OPSEC, Tip)
              if (_isFiltersExpanded) _buildAdvancedFilterPanel(isTr, favCount, customCount),

              const SizedBox(height: 4),

              // 5. Komut Listesi
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(isTr)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: math.min(_displayLimit, filtered.length),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildCommandCard(item, isTr);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showBackToTop)
                FloatingActionButton.small(
                  heroTag: 'fab_top',
                  backgroundColor: AppTheme.bgCard,
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.arrow_upward, color: AppTheme.textPrimary, size: 18),
                ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'fab_add',
                backgroundColor: AppTheme.redTeam,
                onPressed: _openAddCustomCommandDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: Text(
                  isTr ? 'Özel Komut Ekle' : 'Add Custom Command',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularToolChip({
    required String key,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 15,
          color: isSelected ? Colors.white : color,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(40) : color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        selectedColor: color.withAlpha(180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        onSelected: (_) {
          _service.setSelectedTool(isSelected ? 'all' : key);
        },
      ),
    );
  }

  Widget _buildAdvancedFilterPanel(bool isTr, int favCount, int customCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.redTeam.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GELİŞMİŞ FİLTRELER',
                style: TextStyle(color: AppTheme.redTeam, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              if (_service.activeFiltersCount > 0)
                TextButton.icon(
                  onPressed: _service.resetAllFilters,
                  icon: const Icon(Icons.clear_all, size: 14, color: AppTheme.textMuted),
                  label: Text(isTr ? 'Filtreleri Sıfırla' : 'Reset Filters', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Tip Filtresi (Tümü, Favoriler, Özel Komutlar)
          Row(
            children: [
              _buildSmallFilterChip('all', 'Tümü', _service.selectedFilterType == 'all', (v) => _service.setSelectedFilterType('all')),
              const SizedBox(width: 6),
              _buildSmallFilterChip('favorites', '⭐ Favorilerim ($favCount)', _service.selectedFilterType == 'favorites', (v) => _service.setSelectedFilterType('favorites')),
              const SizedBox(width: 6),
              _buildSmallFilterChip('custom', '✏️ Özel Komutlarım ($customCount)', _service.selectedFilterType == 'custom', (v) => _service.setSelectedFilterType('custom')),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Platform Filtresi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSmallFilterChip('all', 'Tüm Platformlar', _service.selectedPlatform == 'all', (v) => _service.setSelectedPlatform('all')),
                const SizedBox(width: 6),
                _buildSmallFilterChip('Linux CLI', '🐧 Linux CLI', _service.selectedPlatform == 'Linux CLI', (v) => _service.setSelectedPlatform('Linux CLI')),
                const SizedBox(width: 6),
                _buildSmallFilterChip('PowerShell', '⚡ PowerShell', _service.selectedPlatform == 'PowerShell', (v) => _service.setSelectedPlatform('PowerShell')),
                const SizedBox(width: 6),
                _buildSmallFilterChip('Windows CMD / Binary', '🪟 Windows CMD', _service.selectedPlatform == 'Windows CMD / Binary', (v) => _service.setSelectedPlatform('Windows CMD / Binary')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. OPSEC Etiketleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OpsecTag.values.map((tag) {
                final isSelected = _service.selectedOpsecTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(tag.label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                    backgroundColor: AppTheme.bgDark,
                    selectedColor: tag.color.withAlpha(160),
                    onSelected: (_) => _service.setSelectedOpsecTag(tag),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFilterChip(String id, String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: AppTheme.bgDark,
      selectedColor: AppTheme.redTeam.withAlpha(180),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppTheme.redTeam : AppTheme.border),
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildTargetContextCard(bool isTr) {
    final ctx = _service.targetContext;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isConfigExpanded ? AppTheme.toolsAmber : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          // Header summary
          InkWell(
            onTap: () {
              setState(() {
                _isConfigExpanded = !_isConfigExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.toolsAmber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gps_fixed, color: AppTheme.toolsAmber, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr ? 'CANLI PENTEST HEDEFİ & DİNLEYİCİ BAĞLAMI' : 'LIVE TARGET & LISTENER CONTEXT',
                          style: const TextStyle(
                            color: AppTheme.toolsAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '🎯 ${ctx.targetIp}:${ctx.targetPort} | 📡 ${ctx.lhost}:${ctx.lport} | 👤 ${ctx.user} | 🌐 ${ctx.targetDomain}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isConfigExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Genişletilebilir Parametre Formu
          if (_isConfigExpanded) ...[
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Row 1: Target IP & Port
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildParamField(
                          controller: _targetIpCtrl,
                          label: 'TARGET_IP',
                          hint: '10.10.10.100',
                          icon: Icons.adjust,
                          onChanged: (v) {
                            _service.updateParameters(
                              targetIp: v,
                              targetUrl: 'http://$v:${_targetPortCtrl.text}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildParamField(
                          controller: _targetPortCtrl,
                          label: 'PORT',
                          hint: '80',
                          icon: Icons.numbers,
                          onChanged: (v) => _service.updateParameters(targetPort: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: LHOST & LPORT
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildParamField(
                          controller: _lhostCtrl,
                          label: 'LHOST (Senin IP)',
                          hint: '10.10.14.5',
                          icon: Icons.settings_ethernet,
                          onChanged: (v) => _service.updateParameters(lhost: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildParamField(
                          controller: _lportCtrl,
                          label: 'LPORT',
                          hint: '4444',
                          icon: Icons.hearing,
                          onChanged: (v) => _service.updateParameters(lport: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Domain & User
                  Row(
                    children: [
                      Expanded(
                        child: _buildParamField(
                          controller: _targetDomainCtrl,
                          label: 'DOMAIN',
                          hint: 'target.local',
                          icon: Icons.domain,
                          onChanged: (v) => _service.updateParameters(targetDomain: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildParamField(
                          controller: _userCtrl,
                          label: 'USER',
                          hint: 'admin',
                          icon: Icons.person,
                          onChanged: (v) => _service.updateParameters(user: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 4: Password & Wordlist
                  Row(
                    children: [
                      Expanded(
                        child: _buildParamField(
                          controller: _passCtrl,
                          label: 'PASSWORD',
                          hint: 'Password123!',
                          icon: Icons.lock,
                          onChanged: (v) => _service.updateParameters(password: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildParamField(
                          controller: _wordlistCtrl,
                          label: 'WORDLIST',
                          hint: '/path/to/wordlist.txt',
                          icon: Icons.list_alt,
                          onChanged: (v) => _service.updateParameters(wordlist: v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.sysAdmin, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tüm komutlar anında derlenir',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await _service.resetToDefaults();
                          _syncControllersWithContext();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh, size: 14, color: AppTheme.redTeam),
                        label: Text(
                          isTr ? 'Varsayılanlara Sıfırla' : 'Reset Defaults',
                          style: const TextStyle(fontSize: 11, color: AppTheme.redTeam),
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParamField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            prefixIcon: Icon(icon, size: 13, color: AppTheme.textMuted),
            prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 0),
            filled: true,
            fillColor: AppTheme.bgDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.redTeam, width: 1.2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCommandCard(CommandItem item, bool isTr) {
    final compiledCmd = _service.compile(item.template);

    // Kategori rengi
    Color catColor = AppTheme.redTeam;
    final catObj = _service.categories.where((c) => c.id == item.category).firstOrNull;
    if (catObj != null) {
      catColor = _parseHex(catObj.color);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isFavorite ? Colors.amber.withAlpha(120) : AppTheme.border,
          width: item.isFavorite ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tool name badge, Category name, Platform, OPSEC tag & Favorite star
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            child: Row(
              children: [
                // Tool badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: catColor.withAlpha(120)),
                  ),
                  child: Text(
                    item.tool.toUpperCase(),
                    style: TextStyle(
                      color: catColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Platform badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    item.platform,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                // OPSEC badge
                if (item.opsec == 'stealth')
                  _buildMiniBadge('EDR Sessiz', const Color(0xFF10B981))
                else if (item.opsec == 'offline')
                  _buildMiniBadge('Offline Kırma', const Color(0xFF8B5CF6))
                else if (item.opsec == 'safe')
                  _buildMiniBadge('Pasif', const Color(0xFF3B82F6)),

                const Spacer(),

                // Favori Yıldızı
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star : Icons.star_border,
                    color: item.isFavorite ? Colors.amber : AppTheme.textMuted,
                    size: 20,
                  ),
                  tooltip: item.isFavorite ? 'Favori Notunu Gör/Düzenle' : 'Favorilere Ekle',
                  onPressed: () => _openFavoriteDialog(item),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              item.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Kullanıcı Özel Notu Varsa Göster
          if (item.userNote != null && item.userNote!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.userNote!,
                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

          // Terminal Canlı Komut Kutusu
          InkWell(
            onTap: () => _copyToClipboard(compiledCmd, item.tool),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withAlpha(60), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        color: AppTheme.sysAdmin,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      compiledCmd,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.copy, size: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // İnteraktif Değişken Çipleri (Tıklanınca anında parametreyi düzenler)
          if (item.variables.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.variables.map((v) {
                  String val = '';
                  final ctx = _service.targetContext;
                  if (v == 'TARGET_IP') val = ctx.targetIp;
                  if (v == 'PORT' || v == 'TARGET_PORT') val = ctx.targetPort;
                  if (v == 'TARGET_URL') val = ctx.targetUrl;
                  if (v == 'DOMAIN' || v == 'TARGET_DOMAIN') val = ctx.targetDomain;
                  if (v == 'LHOST') val = ctx.lhost;
                  if (v == 'LPORT') val = ctx.lport;
                  if (v == 'USER') val = ctx.user;
                  if (v == 'WORDLIST') val = ctx.wordlist;

                  return ActionChip(
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppTheme.bgDark,
                    side: const BorderSide(color: AppTheme.border),
                    avatar: const Icon(Icons.edit, size: 11, color: AppTheme.blueTeam),
                    label: Text(
                      '$v: ${val.length > 18 ? "${val.substring(0, 15)}..." : val}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textMuted),
                    ),
                    onPressed: () => _openQuickEditParamDialog(v, val),
                  );
                }).toList(),
              ),
            ),

          // Alt Aksiyon Butonları
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Özel komut ise silme butonu
                if (item.isUserCreated) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.redTeam),
                    tooltip: 'Özel Komutu Sil',
                    onPressed: () => _service.deleteCustomCommand(item.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                ],
                // İlgili HackTricks Dokümanı
                if (item.docPath.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleScreen(
                            articleId: item.docPath,
                            initialTitle: item.docTitle,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book, size: 14, color: AppTheme.textSecondary),
                    label: Text(
                      isTr ? 'Dokümanda Oku' : 'Read Doc',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                  ),
                  const SizedBox(width: 6),
                ],
                // Notlara Ekle
                IconButton(
                  icon: const Icon(Icons.note_add_outlined, size: 18, color: AppTheme.textSecondary),
                  tooltip: isTr ? 'Not Defterine Ekle' : 'Add to Scratchpad',
                  onPressed: () => _addToScratchpad(item, compiledCmd),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                // Kopyala Butonu
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(compiledCmd, item.tool),
                  icon: const Icon(Icons.copy, size: 13, color: Colors.white),
                  label: Text(
                    isTr ? 'Kopyala' : 'Copy',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: catColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(bool isTr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 54, color: AppTheme.textMuted.withAlpha(100)),
          const SizedBox(height: 14),
          Text(
            isTr ? 'Arama kriterlerine uygun komut bulunamadı' : 'No commands matched your filters',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTr ? 'Farklı bir araç, platform veya arama kelimesi deneyin.' : 'Try a different tool, platform, or search term.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _service.resetAllFilters,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(isTr ? 'Filtreleri Temizle' : 'Reset All Filters'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redTeam),
          ),
        ],
      ),
    );
  }
}
