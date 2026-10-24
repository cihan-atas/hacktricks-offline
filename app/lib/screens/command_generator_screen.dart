import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/command_models.dart';
import '../services/command_service.dart';
import '../services/content_service.dart';
import '../services/scratchpad_service.dart';
import '../theme/app_theme.dart';
import 'article_screen.dart';

class CommandGeneratorScreen extends StatefulWidget {
  const CommandGeneratorScreen({super.key});

  @override
  State<CommandGeneratorScreen> createState() => _CommandGeneratorScreenState();
}

class _CommandGeneratorScreenState extends State<CommandGeneratorScreen> {
  final CommandService _cmdService = CommandService();
  final ContentService _contentService = ContentService();
  final ScratchpadService _scratchpadService = ScratchpadService();

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isConfigExpanded = false;

  // Controllers for config fields
  late TextEditingController _targetIpCtrl;
  late TextEditingController _targetPortCtrl;
  late TextEditingController _targetDomainCtrl;
  late TextEditingController _targetUrlCtrl;
  late TextEditingController _lhostCtrl;
  late TextEditingController _lportCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _wordlistCtrl;

  @override
  void initState() {
    super.initState();
    _targetIpCtrl = TextEditingController(text: _cmdService.targetIp);
    _targetPortCtrl = TextEditingController(text: _cmdService.targetPort);
    _targetDomainCtrl = TextEditingController(text: _cmdService.targetDomain);
    _targetUrlCtrl = TextEditingController(text: _cmdService.targetUrl);
    _lhostCtrl = TextEditingController(text: _cmdService.lhost);
    _lportCtrl = TextEditingController(text: _cmdService.lport);
    _userCtrl = TextEditingController(text: _cmdService.user);
    _passCtrl = TextEditingController(text: _cmdService.password);
    _wordlistCtrl = TextEditingController(text: _cmdService.wordlist);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _targetIpCtrl.dispose();
    _targetPortCtrl.dispose();
    _targetDomainCtrl.dispose();
    _targetUrlCtrl.dispose();
    _lhostCtrl.dispose();
    _lportCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _wordlistCtrl.dispose();
    super.dispose();
  }

  void _syncControllersWithService() {
    _targetIpCtrl.text = _cmdService.targetIp;
    _targetPortCtrl.text = _cmdService.targetPort;
    _targetDomainCtrl.text = _cmdService.targetDomain;
    _targetUrlCtrl.text = _cmdService.targetUrl;
    _lhostCtrl.text = _cmdService.lhost;
    _lportCtrl.text = _cmdService.lport;
    _userCtrl.text = _cmdService.user;
    _passCtrl.text = _cmdService.password;
    _wordlistCtrl.text = _cmdService.wordlist;
  }

  Color _parseHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.redTeam;
    }
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'recon':
        return Icons.radar;
      case 'web':
        return Icons.language;
      case 'services':
        return Icons.dns;
      case 'shells_pivoting':
        return Icons.swap_horiz;
      case 'privesc':
        return Icons.arrow_upward;
      case 'auth_cracking':
        return Icons.lock_open;
      default:
        return Icons.terminal;
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
    _scratchpadService.appendContent(note);
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

  @override
  Widget build(BuildContext context) {
    final isTr = _contentService.currentLanguage == 'tr';

    return ListenableBuilder(
      listenable: _cmdService,
      builder: (context, _) {
        final filtered = _cmdService.filteredCommands;
        final categories = _cmdService.categories;

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
                Text(
                  isTr ? 'Arsenal Komutları' : 'Command Arsenal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isConfigExpanded ? Icons.tune : Icons.tune_outlined,
                  color: _isConfigExpanded ? AppTheme.redTeam : AppTheme.textPrimary,
                ),
                tooltip: isTr ? 'Hedef & Dinleyici Parametreleri' : 'Target & Listener Settings',
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
              // 1. Hedef Parametreleri Kartı (Akordeon)
              _buildTargetConfigCard(isTr),

              // 2. Arama Çubuğu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isTr
                        ? 'Komut, araç (nmap, ffuf, chisel, impacket) veya başlık ara...'
                        : 'Search command, tool (nmap, ffuf, chisel, impacket)...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _cmdService.setSearchQuery('');
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
                  onChanged: (val) {
                    _cmdService.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),

              // 3. Kategori Çipleri (Yatay Kaydırılabilir)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildCategoryChip(
                      id: 'all',
                      label: isTr ? 'Tümü' : 'All',
                      count: _cmdService.countForCategory('all'),
                      icon: Icons.apps,
                      color: AppTheme.redTeam,
                      isSelected: _cmdService.selectedCategory == 'all',
                    ),
                    ...categories.map((cat) {
                      final catColor = _parseHex(cat.color);
                      final isSelected = _cmdService.selectedCategory == cat.id;
                      return _buildCategoryChip(
                        id: cat.id,
                        label: isTr ? cat.name : cat.nameEn,
                        count: _cmdService.countForCategory(cat.id),
                        icon: _getCategoryIcon(cat.id),
                        color: catColor,
                        isSelected: isSelected,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 4. Komut Listesi
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(isTr)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildCommandCard(item, isTr);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String id,
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
          size: 16,
          color: isSelected ? Colors.white : color,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(40)
                    : color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        onSelected: (_) {
          _cmdService.setSelectedCategory(id);
        },
      ),
    );
  }

  Widget _buildTargetConfigCard(bool isTr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isConfigExpanded ? AppTheme.redTeam : AppTheme.border,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.redTeam.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gps_fixed, color: AppTheme.redTeam, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr ? 'CANLI PENTEST HEDEFİ & DİNLEYİCİ' : 'LIVE TARGET & LISTENER CONFIG',
                          style: const TextStyle(
                            color: AppTheme.redTeam,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '🎯 ${_cmdService.targetIp} | 📡 ${_cmdService.lhost}:${_cmdService.lport} | 👤 ${_cmdService.user}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
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

          // Collapsible input form
          if (_isConfigExpanded) ...[
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Row 1: Target IP & Target Port
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
                            _cmdService.updateParameters(
                              targetIp: v,
                              targetUrl: 'http://$v:${_targetPortCtrl.text}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: _buildParamField(
                          controller: _targetPortCtrl,
                          label: 'PORT',
                          hint: '80',
                          icon: Icons.numbers,
                          onChanged: (v) => _cmdService.updateParameters(targetPort: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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
                          onChanged: (v) => _cmdService.updateParameters(lhost: v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: _buildParamField(
                          controller: _lportCtrl,
                          label: 'LPORT',
                          hint: '4444',
                          icon: Icons.hearing,
                          onChanged: (v) => _cmdService.updateParameters(lport: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Domain & User
                  Row(
                    children: [
                      Expanded(
                        child: _buildParamField(
                          controller: _targetDomainCtrl,
                          label: 'DOMAIN',
                          hint: 'target.local',
                          icon: Icons.domain,
                          onChanged: (v) => _cmdService.updateParameters(targetDomain: v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildParamField(
                          controller: _userCtrl,
                          label: 'USER',
                          hint: 'admin',
                          icon: Icons.person,
                          onChanged: (v) => _cmdService.updateParameters(user: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 4: Password & Wordlist
                  Row(
                    children: [
                      Expanded(
                        child: _buildParamField(
                          controller: _passCtrl,
                          label: 'PASSWORD',
                          hint: 'Password123!',
                          icon: Icons.lock,
                          onChanged: (v) => _cmdService.updateParameters(password: v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildParamField(
                          controller: _wordlistCtrl,
                          label: 'WORDLIST',
                          hint: '/path/to/wordlist.txt',
                          icon: Icons.list_alt,
                          onChanged: (v) => _cmdService.updateParameters(wordlist: v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Reset & Auto-save indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.sysAdmin, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Parametreler otomatik kaydedilir',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await _cmdService.resetToDefaults();
                          _syncControllersWithService();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh, size: 14, color: AppTheme.redTeam),
                        label: Text(
                          isTr ? 'Varsayılanlara Dön' : 'Reset Defaults',
                          style: const TextStyle(fontSize: 11, color: AppTheme.redTeam),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
        const SizedBox(height: 4),
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
            prefixIcon: Icon(icon, size: 14, color: AppTheme.textMuted),
            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
            filled: true,
            fillColor: AppTheme.bgDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    final compiledCmd = _cmdService.compile(item.template);

    // Kategori rengi
    Color catColor = AppTheme.redTeam;
    final catObj = _cmdService.categories.where((c) => c.id == item.category).firstOrNull;
    if (catObj != null) {
      catColor = _parseHex(catObj.color);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tool name badge, Category name & variables badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                // Tool badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const SizedBox(width: 8),
                // Category label
                if (catObj != null) ...[
                  Text(
                    isTr ? catObj.name : catObj.nameEn,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                // Variables count badge
                if (item.variables.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.blueTeam.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.variables.length} param',
                      style: const TextStyle(
                        color: AppTheme.blueTeam,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Title / Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(
              item.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Terminal Canlı Komut Kutusu
          InkWell(
            onTap: () => _copyToClipboard(compiledCmd, item.tool),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

          // Action Buttons: Kopyala, Dokümanda Gör, Notlara Ekle
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
                  icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                  label: Text(
                    isTr ? 'Kopyala' : 'Copy',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: catColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            isTr ? 'Komut bulunamadı' : 'No commands found',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTr ? 'Farklı bir arama kelimesi veya kategori deneyin.' : 'Try a different search term or category.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
