import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../screens/movie_detail_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomSearchDelegate extends SearchDelegate {
  final String selectedCategory;
  final List<Movie> Function(String) getMoviesForCategory;
  final CacheManager cacheManager;

  CustomSearchDelegate({
    required this.selectedCategory,
    required this.getMoviesForCategory,
    required this.cacheManager,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final movies = getMoviesForCategory(selectedCategory);
    final filteredMovies = movies
        .where((movie) => movie.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = filteredMovies[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: movie.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            cacheManager: cacheManager,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
          title: Text(
            movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            movie.description.isNotEmpty ? movie.description : 'Sin descripción disponible',
            style: const TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(movie: movie),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final movies = getMoviesForCategory(selectedCategory);
    final filteredMovies = movies
        .where((movie) => movie.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = filteredMovies[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: movie.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            cacheManager: cacheManager,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
          title: Text(
            movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            movie.description.isNotEmpty ? movie.description : 'Sin descripción disponible',
            style: const TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            query = movie.title;
            showResults(context);
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 31),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black87,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
        border: InputBorder.none,
      ),
    );
  }
}