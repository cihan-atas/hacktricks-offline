import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';
import 'article_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ContentService _contentService = ContentService();
  final TextEditingController _controller = TextEditingController();
  List<SearchIndexItem> _results = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final res = _contentService.search(query, pillarFilter: _selectedFilter);
    setState(() => _results = res);
  }

  Color _getPillarColor(String pillarId) {
    final pillar = _contentService.getPillarById(pillarId);
    if (pillar != null && pillar.color.isNotEmpty) {
      try {
        final hex = pillar.color.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return AppTheme.redTeam;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = _contentService.currentLanguage == 'tr';
    final totalDocs = _contentService.searchIndex.length;
    final pillars = _contentService.pillars;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(isTr ? 'Hızlı Çevrimdışı Arama' : 'Fast Offline Search'),
      ),
      body: Column(
        children: [
          // Arama Girişi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: false,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: isTr
                    ? 'Araç, teknik, CVE veya komut ara... (Örn: nmap, sqli, privesc, cve-2024)'
                    : 'Search tool, technique, CVE or command... (e.g. nmap, sqli, privesc)',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 20),
                        onPressed: () {
                          _controller.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.bgCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppTheme.redTeam, width: 1.5),
                ),
              ),
            ),
          ),

          // Dinamik HackTricks Kategori Filtre Butonları (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Tümü Çipi
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: _selectedFilter == 'all',
                    label: Text(isTr ? 'Tümü ($totalDocs)' : 'All ($totalDocs)'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedFilter == 'all' ? Colors.white : AppTheme.textSecondary,
                    ),
                    backgroundColor: AppTheme.bgCard,
                    selectedColor: AppTheme.redTeam.withAlpha(120),
                    side: BorderSide(
                      color: _selectedFilter == 'all' ? AppTheme.redTeam : AppTheme.border,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedFilter = 'all');
                      _performSearch(_controller.text);
                    },
                  ),
                ),
                // Gerçek HackTricks Sütunları
                ...pillars.map((p) {
                  final isSelected = _selectedFilter == p.id;
                  final pColor = _getPillarColor(p.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(p.name),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      backgroundColor: AppTheme.bgCard,
                      selectedColor: pColor.withAlpha(140),
                      side: BorderSide(
                        color: isSelected ? pColor : AppTheme.border,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedFilter = isSelected ? 'all' : p.id);
                        _performSearch(_controller.text);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Arama Sonuçları
          Expanded(
            child: _controller.text.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.manage_search, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          isTr
                              ? '$totalDocs HackTricks dokümanı içinde anında çevrimdışı arama yapın.'
                              : 'Search instantly across $totalDocs HackTricks documents offline.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              isTr
                                  ? '"${_controller.text}" ile eşleşen doküman bulunamadı.'
                                  : 'No documents found matching "${_controller.text}".',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final pillarColor = _getPillarColor(item.pillarId);

                          return Card(
                            color: AppTheme.bgCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArticleScreen(
                                      articleId: item.id,
                                      initialTitle: item.title,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: pillarColor.withAlpha(30),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: pillarColor.withAlpha(80)),
                                          ),
                                          child: Text(
                                            item.category.isNotEmpty
                                                ? item.category
                                                : item.pillarId.replaceAll('_', ' ').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: pillarColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item.path.split('/').last,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (item.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
