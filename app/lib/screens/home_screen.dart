import 'package:flutter/material.dart';
import '../services/content_service.dart';
import '../services/app_state.dart';
import '../services/command_service.dart';
import '../theme/app_theme.dart';
import 'article_screen.dart';
import 'pillar_screen.dart';
import 'search_screen.dart';
import 'scratchpad_screen.dart';
import 'command_generator_screen.dart';

class HomeScreen extends StatelessWidget {
  final ContentService contentService = ContentService();
  final AppState appState = AppState();
  final CommandService commandService = CommandService();

  HomeScreen({super.key});

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.redTeam;
    }
  }

  IconData _getPillarIcon(String id) {
    if (id.contains('web')) return Icons.language;
    if (id.contains('network')) return Icons.router;
    if (id.contains('windows')) return Icons.desktop_windows;
    if (id.contains('linux')) return Icons.terminal;
    if (id.contains('macos')) return Icons.laptop_mac;
    if (id.contains('mobile')) return Icons.phone_android;
    if (id.contains('cloud')) return Icons.cloud;
    if (id.contains('binary') || id.contains('reversing')) return Icons.memory;
    if (id.contains('ai')) return Icons.smart_toy;
    if (id.contains('crypto') || id.contains('blockchain')) return Icons.lock;
    if (id.contains('hardware')) return Icons.developer_board;
    if (id.contains('privacy')) return Icons.visibility_off;
    return Icons.shield_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appState, contentService]),
      builder: (context, _) {
        final pillars = contentService.pillars;
        final totalArticles = contentService.searchIndex.length;
        final readCount = appState.readCount;
        final progressPercent = totalArticles > 0 ? (readCount / totalArticles) : 0.0;
        final isTr = contentService.currentLanguage == 'tr';

        // Deterministik Günün Tekniği
        final todaySeed = DateTime.now().day + DateTime.now().month * 31;
        final allArticles = contentService.searchIndex;
        final dailyArticle = allArticles.isNotEmpty
            ? allArticles[todaySeed % allArticles.length]
            : null;

        // Son Okunan Konu
        final lastArticle = appState.lastReadId != null && allArticles.any((a) => a.id == appState.lastReadId)
            ? allArticles.firstWhere((a) => a.id == appState.lastReadId)
            : null;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderHighlight, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo_small.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'HackTricks Vault',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              // Dil Seçici Butonu
              TextButton.icon(
                onPressed: () {
                  final newLang = isTr ? 'en' : 'tr';
                  contentService.switchLanguage(newLang);
                },
                icon: Text(
                  isTr ? '🇹🇷' : '🇬🇧',
                  style: const TextStyle(fontSize: 16),
                ),
                label: Text(
                  isTr ? 'TR' : 'EN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Arama Butonu
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              ),
              // Not Defteri
              IconButton(
                icon: const Icon(Icons.note_alt_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScratchpadScreen()),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Hero İlerleme Kartı
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.bgCard,
                      AppTheme.redTeam.withAlpha(25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderHighlight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isTr ? 'ÖĞRENME İLERLEMESİ' : 'LEARNING PROGRESS',
                          style: const TextStyle(
                            color: AppTheme.redTeam,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.sysAdmin.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.sysAdmin.withAlpha(80)),
                          ),
                          child: Text(
                            '%${(progressPercent * 100).toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppTheme.sysAdmin,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: AppTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.redTeam),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Metrikler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          Icons.menu_book,
                          '$readCount/$totalArticles',
                          isTr ? 'Okunan Konu' : 'Topics Read',
                          AppTheme.redTeam,
                        ),
                        _buildMetric(
                          Icons.bookmark,
                          '${contentService.bookmarkedIds.length}',
                          isTr ? 'Yer İmleri' : 'Bookmarks',
                          AppTheme.blueTeam,
                        ),
                        _buildMetric(
                          Icons.category,
                          '${pillars.length}',
                          isTr ? 'Kategori' : 'Categories',
                          AppTheme.sysAdmin,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Kaldığın Yerden Devam Et (Varsa)
              if (lastArticle != null && lastArticle.id.isNotEmpty) ...[
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleScreen(articleId: lastArticle.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.blueTeam.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.blueTeam.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: AppTheme.blueTeam, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr ? 'Kaldığın Yerden Devam Et' : 'Resume Reading',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastArticle.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Günün Tekniği Kartı
              if (dailyArticle != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.toolsAmber.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: AppTheme.toolsAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTr ? 'GÜNÜN ODAK NOKTASI' : 'DAILY SPOTLIGHT',
                              style: const TextStyle(
                                color: AppTheme.toolsAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dailyArticle.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArticleScreen(articleId: dailyArticle.id),
                            ),
                          );
                        },
                        child: Text(isTr ? 'İncele' : 'View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3.5 Arsenal Canlı Komut Üretici Kartı
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommandGeneratorScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.bgCard,
                        const Color(0xFF10b981).withAlpha(20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10b981).withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.terminal, color: Color(0xFF10b981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isTr ? 'KOMUT ARSENALİ' : 'COMMAND ARSENAL',
                                  style: const TextStyle(
                                    color: Color(0xFF10b981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10b981).withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ListenableBuilder(
                                    listenable: commandService,
                                    builder: (context, _) {
                                      final count = commandService.commands.isNotEmpty
                                          ? commandService.commands.length
                                          : 17100;
                                      final countStr = count >= 1000
                                          ? '${(count / 1000).toStringAsFixed(1)}K+'
                                          : '$count+';
                                      return Text(
                                        '$countStr Canlı',
                                        style: const TextStyle(
                                          color: Color(0xFF10b981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isTr
                                  ? 'Hedef IP ve dinleyici parametrelerine göre canlı derlenen pentest komutları'
                                  : 'Live-compiled pentest commands customized for your target IP and listeners',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Kategoriler Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTr ? 'KÜTÜPHANE VE KATEGORİLER' : 'LIBRARY & CATEGORIES',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${pillars.length} ${isTr ? 'Bölüm' : 'Pillars'}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Kategori Listesi / Kartları
              ...pillars.map((pillar) {
                final pColor = _parseColor(pillar.color);
                final pIcon = _getPillarIcon(pillar.id);
                final totalArticlesInPillar = pillar.modules.fold<int>(
                  0,
                  (sum, m) => sum + m.articles.length,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PillarScreen(pillar: pillar),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: pColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: pColor.withAlpha(80)),
                              ),
                              child: Icon(pIcon, color: pColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pillar.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$totalArticlesInPillar ${isTr ? 'konu & teknik' : 'articles & techniques'}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: pColor.withAlpha(160)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
