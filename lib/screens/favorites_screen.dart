import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../utils/favorites_manager.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      ),
      body: FutureBuilder<List<String>>(
        future: FavoritesManager.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar favoritos.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }
          final favorites = snapshot.data ?? [];
          final favoriteMovies = [
            ...Provider.of<MovieProvider>(context, listen: false).popularMovies,
            ...Provider.of<MovieProvider>(context, listen: false).newMovies,
          ].where((movie) => favorites.contains(movie.title)).toList();

          if (favoriteMovies.isEmpty) {
            return const Center(
              child: Text(
                'No hay películas favoritas.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoriteMovies.length,
            itemBuilder: (context, index) {
              final movie = favoriteMovies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: movie.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}