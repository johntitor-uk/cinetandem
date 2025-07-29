import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/movie.dart';

class MovieService {
static const String _baseUrl = 'https://api.themoviedb.org/3';
static const String _accessToken =
'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5MWU4NWFjNDM0YmY0ZDU5NWE1ZjE5Y2I0YmQ2OWNlMyIsIm5iZiI6MTc1MjgwNzI1My42MjUsInN1YiI6IjY4NzliNzU1NGQ3N2EwNDhlNDM4YzllZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.bmrwYVLDBCDDmpdzt4Qok2PG9TQNmDZY9r5VqknYdgc';
static const String _apiKey = '91e85ac434bf4d595a5f19cb4bd69ce3';

Future<List<Movie>> fetchRecentMovies({int count = 200}) async {
final List<Movie> movies = [];
const int moviesPerPage = 20;
final int totalPages = (count / moviesPerPage).ceil();

for (int page = 1; page <= totalPages && movies.length < count; page++) {
final response = await http.get(
Uri.parse(
'$_baseUrl/discover/movie?sort_by=release_date.desc&primary_release_date.lte=2025-07-27&language=es-ES&page=$page'),
headers: {
'Authorization': 'Bearer $_accessToken',
'Accept': 'application/json',
},
);

if (response.statusCode == 200) {
final data = jsonDecode(response.body);
final List<dynamic> results = data['results'] ?? [];
final newMovies = results
    .map((json) => Movie.fromJson(json, isSeries: false))
    .toList();
movies.addAll(newMovies);
} else {
throw Exception(
'Error al cargar películas recientes: ${response.statusCode}');
}
}

return movies.take(count).toList();
}

Future<List<Movie>> fetchMovies({bool isMovies = true}) async {
final String endpoint = isMovies ? '/movie/popular' : '/tv/popular';
final response = await http.get(
Uri.parse('$_baseUrl$endpoint?language=es-ES'),
headers: {
'Authorization': 'Bearer $_accessToken',
'Accept': 'application/json',
},
);

if (response.statusCode == 200) {
final data = jsonDecode(response.body);
final List<dynamic> results = data['results'] ?? [];
return results
    .map((json) => Movie.fromJson(json, isSeries: !isMovies))
    .toList();
} else {
throw Exception('Error al cargar películas: ${response.statusCode}');
}
}

Future<List<Movie>> fetchMoviesByGenre(String genre) async {
final genreMap = {
'acción': '28',
'aventura': '12',
'comedia': '35',
'drama': '18',
'ciencia ficción': '878',
'fantasía': '14',
'terror': '27',
'misterio': '9648',
'romance': '10749',
'documental': '99',
'animación': '16',
'familiar': '10751',
};

final genreId = genreMap[genre.toLowerCase()];
if (genreId == null) {
throw Exception('Género no válido: $genre');
}

final response = await http.get(
Uri.parse(
'$_baseUrl/discover/movie?language=es-ES&with_genres=$genreId'),
headers: {
'Authorization': 'Bearer $_accessToken',
'Accept': 'application/json',
},
);

if (response.statusCode == 200) {
final data = jsonDecode(response.body);
final List<dynamic> results = data['results'] ?? [];
return results
    .map((json) => Movie.fromJson(json, isSeries: false))
    .toList();
} else {
throw Exception('Error al cargar películas por género: ${response.statusCode}');
}
}
}