import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScratchpadItem {
  final String id;
  String title;
  String content;
  String category;
  DateTime updatedAt;

  ScratchpadItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ScratchpadItem.fromJson(Map<String, dynamic> json) => ScratchpadItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    category: json['category'] ?? 'Genel',
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );
}

class ScratchpadService extends ChangeNotifier {
  static final ScratchpadService _instance = ScratchpadService._internal();
  factory ScratchpadService() => _instance;
  ScratchpadService._internal();

  List<ScratchpadItem> _items = [];
  bool _isInitialized = false;

  List<ScratchpadItem> get items => _items;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('ht_scratchpad') ?? [];
    _items = data.map((str) => ScratchpadItem.fromJson(json.decode(str))).toList();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveItem(ScratchpadItem item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.insert(0, item);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((i) => json.encode(i.toJson())).toList();
    await prefs.setStringList('ht_scratchpad', data);
  }
}
