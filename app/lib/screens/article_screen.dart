import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import '../services/app_state.dart';
import '../services/link_navigation_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_block_builder.dart';
import '../widgets/tts_bar.dart';
import 'ai_sheet.dart';
import 'scratchpad_screen.dart';

class _ArticleSection {
  final int index;
  final String title;
  final String body;
  final GlobalKey key;

  _ArticleSection({
    required this.index,
    required this.title,
    required this.body,
    required this.key,
  });
}

class ArticleScreen extends StatefulWidget {
  final String articleId;
  final String? initialTitle;
  final String? targetSectionAnchor;

  const ArticleScreen({
    super.key,
    required this.articleId,
    this.initialTitle,
    this.targetSectionAnchor,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final ContentService _contentService = ContentService();
  final AppState _appState = AppState();
  final TtsService _tts = TtsService();

  ArticleDetail? _article;
  List<_ArticleSection> _sections = [];
  bool _isLoading = true;
  double _fontSizeDelta = 0.0;
  final ScrollController _scrollController = ScrollController();
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArticle() async {
    final article = await _contentService.getArticle(
      widget.articleId,
      fallbackTitle: widget.initialTitle,
    );
    if (mounted) {
      setState(() {
        _article = article;
        _isLoading = false;
        if (article != null) {
          _sections = _parseSections(article.content);
        }
      });
      if (article != null) {
        _appState.recordLastRead(
          id: article.id,
          title: article.title,
          category: article.category,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (widget.targetSectionAnchor != null) {
            _scrollToSectionByAnchor(widget.targetSectionAnchor!);
          } else {
            // Kullanıcı daha önce bu dokümanda bir bölümde kaldıysa otomatik devam et
            final lastSecIdx = _appState.getLastReadSection(article.id);
            if (lastSecIdx != null && lastSecIdx > 0) {
              final targetSec = _sections.firstWhere(
                (s) => s.index == lastSecIdx,
                orElse: () => _sections.first,
              );
              if (targetSec.index > 0) {
                _scrollToSection(targetSec);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.bookmark_added, color: AppTheme.toolsAmber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kaldığınız yerden devam ediliyor: ${targetSec.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTheme.bgCard,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        });
      }
    }
  }

  List<_ArticleSection> _parseSections(String markdown) {
    final headingRegex = RegExp(r'^##\s+(.+)$', multiLine: true);
    final matches = headingRegex.allMatches(markdown).toList();

    if (matches.isEmpty) {
      return [
        _ArticleSection(
          index: 1,
          title: 'Genel İçerik',
          body: markdown,
          key: GlobalKey(),
        ),
      ];
    }

    final sections = <_ArticleSection>[];

    // İlk ## başlığından önceki giriş/tanım kısmı
    if (matches.first.start > 0) {
      final preamble = markdown.substring(0, matches.first.start).trim();
      if (preamble.isNotEmpty) {
        sections.add(
          _ArticleSection(
            index: 0,
            title: 'Giriş & Genel Bakış',
            body: preamble,
            key: GlobalKey(),
          ),
        );
      }
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final title = match.group(1)!.trim();
      final start = match.start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : markdown.length;
      final body = markdown.substring(start, end).trim();

      sections.add(
        _ArticleSection(
          index: i + 1,
          title: title,
          body: body,
          key: GlobalKey(),
        ),
      );
    }

    return sections;
  }

  Color _getPillarColor() {
    if (_article == null) return AppTheme.redTeam;
    final pillar = _contentService.getPillarById(_article!.pillarId);
    if (pillar != null && pillar.color.isNotEmpty) {
      try {
        final hex = pillar.color.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return AppTheme.redTeam;
  }

  void _scrollToSection(_ArticleSection section) {
    final context = section.key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToSectionByAnchor(String anchor) {
    if (_sections.isEmpty) return;
    final cleanAnchor = anchor.replaceAll('-', ' ').replaceAll('_', ' ').toLowerCase().trim();
    for (final sec in _sections) {
      final cleanTitle = sec.title.toLowerCase().trim();
      if (cleanTitle.contains(cleanAnchor) || cleanAnchor.contains(cleanTitle)) {
        _scrollToSection(sec);
        return;
      }
    }
  }

  void _showTableOfContents() {
    if (_article == null || _sections.isEmpty) return;

    final artId = _article!.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final readCount = _appState.getReadSectionsCount(artId);
            final totalCount = _sections.length;
            final progress = totalCount > 0 ? (readCount / totalCount).clamp(0.0, 1.0) : 0.0;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Başlığı ve İlerleme
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.list_alt, color: AppTheme.blueTeam, size: 22),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'İçindekiler & Bölüm İlerlemesi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.sysAdmin.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.sysAdmin.withAlpha(80)),
                                ),
                                child: Text(
                                  '$readCount / $totalCount Okundu',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.sysAdmin,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sysAdmin),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bölümleri tamamladıkça tikleyin. Bir sonraki açılışta son kaldığınız yere otomatik kaydırılır.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final sec = _sections[index];
                          final isSecRead = _appState.isSectionRead(artId, sec.index);
                          final isLastRead = _appState.getLastReadSection(artId) == sec.index;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            leading: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSecRead
                                    ? AppTheme.sysAdmin.withAlpha(30)
                                    : (isLastRead ? AppTheme.toolsAmber.withAlpha(30) : AppTheme.blueTeam.withAlpha(25)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSecRead
                                      ? AppTheme.sysAdmin
                                      : (isLastRead ? AppTheme.toolsAmber : Colors.transparent),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                sec.index == 0 ? '0' : '${sec.index}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSecRead
                                      ? AppTheme.sysAdmin
                                      : (isLastRead ? AppTheme.toolsAmber : AppTheme.blueTeam),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sec.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isLastRead ? FontWeight.bold : FontWeight.w600,
                                      color: isSecRead
                                          ? AppTheme.textSecondary
                                          : (isLastRead ? AppTheme.toolsAmber : AppTheme.textPrimary),
                                      decoration: isSecRead ? TextDecoration.lineThrough : null,
                                      decorationColor: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                if (isLastRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.toolsAmber.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Son Kalınan',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.toolsAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isSecRead ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSecRead ? AppTheme.sysAdmin : AppTheme.textMuted,
                                size: 22,
                              ),
                              tooltip: isSecRead ? 'Okunmadı olarak işaretle' : 'Okundu olarak işaretle',
                              onPressed: () async {
                                await _appState.toggleSectionRead(artId, sec.index);
                                setModalState(() {});
                                if (mounted) setState(() {});
                              },
                            ),
                            onTap: () async {
                              await _appState.setLastReadSection(artId, sec.index);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (mounted) {
                                _scrollToSection(sec);
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _article?.title ?? widget.initialTitle ?? 'Doküman';
    final pillarColor = _getPillarColor();
    final isBookmarked = _appState.isBookmarked(widget.articleId);
    final isRead = _appState.isRead(widget.articleId);

    return ListenableBuilder(
      listenable: _tts,
      builder: (context, _) {
        final isReadingFullDoc = _tts.isPlaying &&
            _tts.currentId == widget.articleId &&
            (_tts.currentSubtitle == 'Tüm Doküman' || _tts.currentSubtitle == null);

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
            actions: [
              // Tüm Dokümanı Sesli Okuma
              IconButton(
                icon: Icon(
                  isReadingFullDoc ? Icons.volume_up : Icons.volume_up_outlined,
                  color: isReadingFullDoc ? AppTheme.blueTeam : AppTheme.textSecondary,
                ),
                tooltip: isReadingFullDoc ? 'Okumayı Durdur' : 'Tüm Dokümanı Sesli Dinle',
                onPressed: () {
                  if (_article == null) return;
                  if (_tts.isPlaying) {
                    _tts.stop();
                  } else {
                    _tts.speak(
                      _article!.content,
                      id: widget.articleId,
                      title: title,
                      subtitle: 'Tüm Doküman',
                    );
                  }
                },
              ),
              // AI Asistanı
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: AppTheme.toolsAmber),
                tooltip: 'AI Asistanı (Açıkla / Soru Sor)',
                onPressed: () {
                  if (_article != null) {
                    showAiAssistantSheet(
                      context,
                      articleId: _article!.id,
                      moduleId: _article!.moduleId,
                      moduleTitle: _article!.category,
                      articleContent: _article!.content,
                      articleTitle: _article!.title,
                    );
                  }
                },
              ),
              // Yer İmi Toggle
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppTheme.toolsAmber : AppTheme.textSecondary,
                ),
                tooltip: isBookmarked ? 'Yer İmlerinden Kaldır' : 'Yer İmlerine Ekle',
                onPressed: () async {
                  final isCurrentlyBookmarked = _appState.isBookmarked(widget.articleId);
                  final messenger = ScaffoldMessenger.of(context);
                  await _appState.toggleBookmark(widget.articleId);
                  if (!mounted) return;
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        !isCurrentlyBookmarked ? 'Yer imlerine eklendi ⭐' : 'Yer imlerinden kaldırıldı',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppTheme.bgCard,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              // Diğer İşlemler (Okundu, İçindekiler, Yazı Boyutu)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                tooltip: 'Diğer Seçenekler',
                onSelected: (val) async {
                  if (val == 'read') {
                    final messenger = ScaffoldMessenger.of(context);
                    await _appState.toggleRead(widget.articleId);
                    setState(() {});
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _appState.isRead(widget.articleId)
                              ? 'Konu tamamlandı olarak işaretlendi! ✓'
                              : 'Okundu işareti kaldırıldı.',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppTheme.bgCard,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (val == 'toc') {
                    _showTableOfContents();
                  } else if (val == 'scratchpad') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScratchpadScreen()),
                    );
                  } else if (val == 'font') {
                    setState(() {
                      _fontSizeDelta = (_fontSizeDelta >= 4.0) ? -2.0 : _fontSizeDelta + 1.5;
                    });
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(
                          isRead ? Icons.check_circle : Icons.check_circle_outline,
                          color: isRead ? AppTheme.sysAdmin : AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(isRead ? 'Okunmadı Olarak İşaretle' : 'Okundu Olarak İşaretle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'scratchpad',
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.toolsAmber, size: 18),
                        SizedBox(width: 10),
                        Text('Ganimet Defterini Aç (Loot)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'toc',
                    child: Row(
                      children: [
                        Icon(Icons.toc, color: AppTheme.blueTeam, size: 18),
                        SizedBox(width: 10),
                        Text('İçindekiler / Bölümler'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'font',
                    child: Row(
                      children: [
                        Icon(Icons.text_fields, color: AppTheme.toolsAmber, size: 18),
                        SizedBox(width: 10),
                        Text('Yazı Boyutu (A+ / A-)'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: const TtsPlayerBar(),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.redTeam),
                )
              : _article == null
                  ? const Center(
                      child: Text(
                        'Doküman yüklenemedi.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : SelectionArea(
                      onSelectionChanged: (SelectedContent? content) {
                        _selectedText = content?.plainText;
                      },
                      contextMenuBuilder: (context, state) {
                        final items = state.contextMenuButtonItems;
                        final snippet = _selectedText?.trim() ?? '';
                        if (snippet.isNotEmpty) {
                          items.insert(
                            0,
                            ContextMenuButtonItem(
                              label: '🔊 Buradan İtibaren Oku',
                              onPressed: () {
                                state.hideToolbar();
                                _tts.speakRemainingFromSnippet(
                                  _article!.content,
                                  snippet,
                                  id: widget.articleId,
                                  title: title,
                                );
                              },
                            ),
                          );
                          items.insert(
                            1,
                            ContextMenuButtonItem(
                              label: '🗣️ Seçileni Oku',
                              onPressed: () {
                                state.hideToolbar();
                                _tts.speakSnippet(
                                  snippet,
                                  id: widget.articleId,
                                  title: title,
                                );
                              },
                            ),
                          );
                        }
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: state.contextMenuAnchors,
                          buttonItems: items,
                        );
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Kategori & Yol Bilgisi Etiketi
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: pillarColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: pillarColor.withAlpha(80), width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.folder_outlined, size: 14, color: pillarColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _article!.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: pillarColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Bölüm Bölüm Render ve Her Bölüme Özel Eylemler
                            ..._sections.map(
                              (sec) => _buildSectionWidget(
                                section: sec,
                                pillarColor: pillarColor,
                                fullTitle: title,
                                fullMarkdown: _article!.content,
                              ),
                            ),

                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildSectionWidget({
    required _ArticleSection section,
    required Color pillarColor,
    required String fullTitle,
    required String fullMarkdown,
  }) {
    final sectionId = '${widget.articleId}_sec_${section.index}';
    final isThisSectionPlaying = _tts.isPlaying &&
        (_tts.currentId == sectionId ||
            (_tts.currentId == widget.articleId && _tts.currentSubtitle?.contains(section.title) == true));

    return Container(
      key: section.key,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bölüm Eylem ve Başlık Çubuğu (Giriş/0 hariç)
          if (section.index > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isThisSectionPlaying
                    ? AppTheme.blueTeam.withAlpha(20)
                    : const Color(0xFF131A26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isThisSectionPlaying
                      ? AppTheme.blueTeam.withAlpha(120)
                      : AppTheme.borderHighlight,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Bölüm Numarası
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pillarColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${section.index}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pillarColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isThisSectionPlaying ? AppTheme.blueTeam : Colors.white,
                      ),
                    ),
                  ),
                  // Sesli Dinle Butonu (Tıkla: Bu bölümü dinle / Basılı tut: Buradan sona kadar dinle)
                  Tooltip(
                    message: 'Tıkla: Bu bölümü dinle\nBasılı tut: Buradan sona kadar dinle',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        if (isThisSectionPlaying) {
                          _tts.stop();
                        } else {
                          _tts.speak(
                            section.body,
                            id: sectionId,
                            title: fullTitle,
                            subtitle: section.title,
                          );
                        }
                      },
                      onLongPress: () {
                        _tts.speakFrom(
                          fullMarkdown,
                          section.body,
                          id: widget.articleId,
                          title: fullTitle,
                          sectionTitle: section.title,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Buradan sona kadar sesli okunuyor... 🔊 (${section.title})'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppTheme.bgCard,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isThisSectionPlaying
                              ? AppTheme.blueTeam.withAlpha(35)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isThisSectionPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                              size: 15,
                              color: isThisSectionPlaying ? AppTheme.blueTeam : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isThisSectionPlaying ? 'Durdur' : 'Dinle',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isThisSectionPlaying ? AppTheme.blueTeam : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // AI ile Bu Bölümü Açıkla
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.toolsAmber),
                    tooltip: 'AI ile Bu Bölümü İncele',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showAiAssistantSheet(
                        context,
                        articleId: _article?.id ?? widget.articleId,
                        moduleId: _article?.moduleId ?? '',
                        moduleTitle: _article?.category ?? '',
                        articleContent: section.body,
                        articleTitle: '$fullTitle · ${section.title}',
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Bölüm Okundu Tik Butonu
                  Builder(
                    builder: (context) {
                      final isSecRead = _appState.isSectionRead(widget.articleId, section.index);
                      return IconButton(
                        icon: Icon(
                          isSecRead ? Icons.check_circle : Icons.check_circle_outline,
                          size: 18,
                          color: isSecRead ? AppTheme.sysAdmin : AppTheme.textMuted,
                        ),
                        tooltip: isSecRead ? 'Okundu işaretini kaldır' : 'Bölümü Tamamla (Okundu İşaretle)',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await _appState.toggleSectionRead(widget.articleId, section.index);
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

          // Markdown Bölüm İçeriği
          MarkdownBody(
            data: section.body,
            selectable: false, // Seçim SelectionArea tarafından yönetiliyor
            builders: {
              'code': CodeElementBuilder(context),
            },
            onTapLink: (text, href, title) {
              LinkNavigationHelper.handleLinkTap(
                context: context,
                href: href,
                text: text,
                currentArticlePath: _article?.path,
                onLocalAnchorTap: (anchor) => _scrollToSectionByAnchor(anchor),
              );
            },
            styleSheet: MarkdownStyleSheet(
              a: const TextStyle(
                color: AppTheme.blueTeam,
                decoration: TextDecoration.underline,
                decorationColor: Color(0x9958A6FF),
                fontWeight: FontWeight.w600,
              ),
              p: TextStyle(
                fontSize: 14.5 + _fontSizeDelta,
                color: AppTheme.textPrimary,
                height: 1.55,
              ),
              h1: TextStyle(
                fontSize: 22 + _fontSizeDelta,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              h2: TextStyle(
                fontSize: 18 + _fontSizeDelta,
                fontWeight: FontWeight.bold,
                color: pillarColor,
                height: 1.4,
              ),
              h3: TextStyle(
                fontSize: 16 + _fontSizeDelta,
                fontWeight: FontWeight.w600,
                color: AppTheme.blueTeam,
                height: 1.4,
              ),
              h4: TextStyle(
                fontSize: 15 + _fontSizeDelta,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              listBullet: TextStyle(
                fontSize: 14 + _fontSizeDelta,
                color: pillarColor,
              ),
              blockquote: TextStyle(
                fontSize: 13.5 + _fontSizeDelta,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                color: const Color(0xFF131A26),
                borderRadius: BorderRadius.circular(6),
                border: const Border(
                  left: BorderSide(color: AppTheme.blueTeam, width: 3),
                ),
              ),
              tableHead: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.blueTeam,
                fontSize: 13,
              ),
              tableBody: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5 + _fontSizeDelta,
              ),
              tableBorder: TableBorder.all(
                color: AppTheme.borderHighlight,
                width: 1,
              ),
              tableCellsPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              horizontalRuleDecoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
              code: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5 + _fontSizeDelta,
                color: AppTheme.toolsAmber,
                backgroundColor: const Color(0xFF1E2638),
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF161922),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
