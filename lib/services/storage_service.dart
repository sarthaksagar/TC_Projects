import 'dart:html' as html;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Map<String, dynamic> _memoryStorage = {};

  Future<void> save(String key, dynamic value) async {
    _memoryStorage[key] = value;
    try {
      html.window.localStorage[key] = value.toString();
    } catch (_) {}
  }

  Future<dynamic> read(String key) async {
    try {
      if (html.window.localStorage.containsKey(key)) {
        return html.window.localStorage[key];
      }
    } catch (_) {}
    return _memoryStorage[key];
  }

  Future<void> remove(String key) async {
    _memoryStorage.remove(key);
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}
