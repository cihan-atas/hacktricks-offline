import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';

class ContentService extends ChangeNotifier {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  String _currentLanguage = 'tr'; // 'tr' veya 'en'
  List<Pillar> _pillars = [];
  List<SearchIndexItem> _searchIndex = [];
  Map<String, dynamic>? _rawArticlesMap;
  final Map<String, ArticleDetail> _articleCache = {};
  Set<String> _bookmarkedIds = {};
  Map<String, dynamic> _stats = {};
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  List<Pillar> get pillars => _pillars;
  List<SearchIndexItem> get searchIndex => _searchIndex;
  Set<String> get bookmarkedIds => _bookmarkedIds;
  Map<String, dynamic> get stats => _stats;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('ht_language') ?? 'tr';
      final savedBookmarks = prefs.getStringList('saved_bookmarks') ?? [];
      _bookmarkedIds = savedBookmarks.toSet();

      await _loadLanguageData(_currentLanguage);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ContentService init hatası: $e');
    }
  }

  Future<void> switchLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    _articleCache.clear();
    _rawArticlesMap = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ht_language', lang);

    await _loadLanguageData(lang);
    notifyListeners();
  }

  Future<void> _loadLanguageData(String lang) async {
    try {
      // 1. Hiyerarşi
      final hierarchyStr = await rootBundle.loadString('assets/data/$lang/hierarchy.json');
      final List<dynamic> hierarchyJson = json.decode(hierarchyStr);
      _pillars = hierarchyJson.map((p) => Pillar.fromJson(p)).toList();

      // 2. Arama İndeksi
      final searchStr = await rootBundle.loadString('assets/data/$lang/search_index.json');
      final List<dynamic> searchJson = json.decode(searchStr);
      _searchIndex = searchJson.map((s) => SearchIndexItem.fromJson(s)).toList();

      // 3. İstatistikler
      try {
        final statsStr = await rootBundle.loadString('assets/data/stats.json');
        _stats = json.decode(statsStr);
      } catch (_) {}
    } catch (e) {
      debugPrint('Dil verisi yüklenirken hata ($lang): $e');
    }
  }

  Future<ArticleDetail?> getArticle(String id, {String? fallbackTitle}) async {
    if (_articleCache.containsKey(id)) {
      return _articleCache[id];
    }

    if (_rawArticlesMap == null) {
      final articlesStr = await rootBundle.loadString('assets/data/$_currentLanguage/articles.json');
      _rawArticlesMap = json.decode(articlesStr) as Map<String, dynamic>;
    }

    if (_rawArticlesMap != null) {
      if (_rawArticlesMap!.containsKey(id)) {
        final detail = ArticleDetail.fromJson(_rawArticlesMap![id]);
        _articleCache[id] = detail;
        return detail;
      }

      // Yol veya dosya adı ile arama
      final normalizedId = id.replaceAll('\\', '/').toLowerCase();
      for (final entry in _rawArticlesMap!.values) {
        if (entry is Map<String, dynamic>) {
          final path = (entry['path'] as String? ?? '').replaceAll('\\', '/').toLowerCase();
          final filename = (entry['filename'] as String? ?? '').toLowerCase();
          final entryId = (entry['id'] as String? ?? '').toLowerCase();

          if (path == normalizedId ||
              path.endsWith(normalizedId) ||
              filename == normalizedId ||
              entryId == normalizedId) {
            final detail = ArticleDetail.fromJson(entry);
            _articleCache[id] = detail;
            return detail;
          }
        }
      }
    }

    // Fallback oluştur
    return ArticleDetail(
      id: id,
      title: fallbackTitle ?? id.split('/').last.replaceAll('.md', ''),
      description: 'Doküman yüklenemedi veya bulunamadı.',
      path: id,
      filename: id.split('/').last,
      pillarId: '',
      moduleId: '',
      category: 'HackTricks',
      content: '# ${fallbackTitle ?? id}\n\nBu dokümanın içeriği henüz yüklenemedi veya bağlantı taşınmış olabilir.',
      searchText: fallbackTitle ?? id,
      isReadme: false,
    );
  }

  Pillar? getPillarById(String id) {
    try {
      return _pillars.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SearchIndexItem> search(String query, {String? pillarFilter}) {
    if (query.trim().isEmpty) return [];

    final cleanQuery = query.trim().toLowerCase();
    final tokens = cleanQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return _searchIndex.where((item) {
      if (pillarFilter != null && pillarFilter != 'all') {
        if (item.pillarId != pillarFilter) {
          return false;
        }
      }

      final text = '${item.title} ${item.description} ${item.category} ${item.path}'.toLowerCase();
      for (final token in tokens) {
        if (!text.contains(token)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();
        if (aTitle.startsWith(cleanQuery) && !bTitle.startsWith(cleanQuery)) return -1;
        if (!aTitle.startsWith(cleanQuery) && bTitle.startsWith(cleanQuery)) return 1;
        return a.title.compareTo(b.title);
      });
  }

  List<SearchIndexItem> getBookmarkedItems() {
    return _searchIndex.where((item) => _bookmarkedIds.contains(item.id)).toList();
  }

  SearchIndexItem? findArticleItem({String? path, String? tool, String? keyword}) {
    if ((path == null || path.trim().isEmpty) &&
        (keyword == null || keyword.trim().isEmpty)) {
      return null;
    }

    final pNorm = path?.replaceAll('\\', '/').toLowerCase().trim() ?? '';
    final kwNorm = keyword?.toLowerCase().trim() ?? '';

    if (pNorm.isNotEmpty) {
      for (final item in _searchIndex) {
        final ip = item.path.toLowerCase();
        if (ip == pNorm || ip.endsWith(pNorm) || pNorm.endsWith(ip)) {
          return item;
        }
      }
      final fname = pNorm.split('/').last;
      if (fname.isNotEmpty) {
        for (final item in _searchIndex) {
          if (item.path.split('/').last.toLowerCase() == fname) {
            return item;
          }
        }
      }
    }

    if (kwNorm.isNotEmpty) {
      for (final item in _searchIndex) {
        if (item.title.toLowerCase().contains(kwNorm)) {
          return item;
        }
      }
    }

    return null;
  }

  Future<void> toggleBookmark(String articleId) async {
    if (_bookmarkedIds.contains(articleId)) {
      _bookmarkedIds.remove(articleId);
    } else {
      _bookmarkedIds.add(articleId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_bookmarks', _bookmarkedIds.toList());
  }

  bool isBookmarked(String articleId) => _bookmarkedIds.contains(articleId);
}
