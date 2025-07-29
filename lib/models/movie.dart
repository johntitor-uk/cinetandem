class Movie {
final int id;
final String title;
final String imageUrl;
final double rating;
final String releaseDate;
final List<String> actors;
final String description;
final String category;

Movie({
required this.id,
required this.title,
required this.imageUrl,
required this.rating,
required this.releaseDate,
required this.actors,
required this.description,
required this.category,
});

factory Movie.fromJson(Map<String, dynamic> json, {bool isSeries = false}) {
final genreMap = {
28: 'Acción',
12: 'Aventura',
35: 'Comedia',
18: 'Drama',
878: 'Ciencia Ficción',
14: 'Fantasía',
27: 'Terror',
9648: 'Misterio',
10749: 'Romance',
99: 'Documental',
16: 'Animación',
10751: 'Familiar',
};

final genreIds = (json['genre_ids'] as List<dynamic>?) ?? [];
String category = genreIds.isNotEmpty ? genreMap[genreIds[0]] ?? 'Desconocida' : 'Desconocida';

return Movie(
id: json['id'] ?? 0,
title: json[isSeries ? 'name' : 'title'] ?? 'Sin título',
imageUrl: json['poster_path'] != null
? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
    : 'https://via.placeholder.com/500x750',
rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
releaseDate: json[isSeries ? 'first_air_date' : 'release_date'] ?? 'Desconocida',
actors: [], // TMDb no proporciona actores en listados; se puede obtener en detalles
description: json['overview']?.isNotEmpty == true ? json['overview'] : 'Sin descripción disponible',
category: category,
);
}
}