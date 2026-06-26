import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent set of favorited listing ids, exposed as a reactive provider.
class FavoritesStore extends StateNotifier<Set<String>> {
  FavoritesStore() : super(const {}) {
    _hydrate();
  }
  static const _key = 'twende.favorites';

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key)?.toSet() ?? const {};
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool contains(String id) => state.contains(id);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesStore, Set<String>>((_) => FavoritesStore());
