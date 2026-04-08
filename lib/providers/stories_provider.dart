import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';

class StoriesProvider extends ChangeNotifier {
  List<Story> _stories = [];
  static const String _storageKey = 'storybook_stories';

  List<Story> get stories => _stories;
  List<Story> get favorites => _stories.where((s) => s.isFavorite).toList();

  Future<void> loadStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _stories = list
            .map((e) => Story.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _stories = sampleStories();
        await _save();
      }
    } catch (_) {
      _stories = sampleStories();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_stories.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  String addStory({
    required String title,
    required String coverColor,
    required String coverEmoji,
    required List<StoryPage> pages,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final story = Story(
      id: id,
      title: title,
      coverColor: coverColor,
      coverEmoji: coverEmoji,
      pages: pages,
      createdAt: now,
      updatedAt: now,
    );
    _stories.insert(0, story);
    _save();
    notifyListeners();
    return id;
  }

  void updateStory(String id, Story updated) {
    final index = _stories.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stories[index] = updated.copyWith(updatedAt: DateTime.now());
      _save();
      notifyListeners();
    }
  }

  void deleteStory(String id) {
    _stories.removeWhere((s) => s.id == id);
    _save();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _stories.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stories[index] = _stories[index].copyWith(
        isFavorite: !_stories[index].isFavorite,
        updatedAt: DateTime.now(),
      );
      _save();
      notifyListeners();
    }
  }

  Story? getStory(String id) {
    try {
      return _stories.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
