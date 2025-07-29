import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _favoritesKey = 'favorites';

  // Agrega una película a favoritos
  static Future<void> addFavorite(String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    if (!favorites.contains(movieTitle)) {
      favorites.add(movieTitle);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Elimina una película de favoritos
  static Future<void> removeFavorite(String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    if (favorites.contains(movieTitle)) {
      favorites.remove(movieTitle);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Verifica si una película está en favoritos
  static Future<bool> isFavorite(String movieTitle) async {
    final favorites = await getFavorites();
    return favorites.contains(movieTitle);
  }

  // Obtiene la lista de películas favoritas
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }
}