import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MovieProvider with ChangeNotifier {
  List<Movie> _popularMovies = [];
  List<Movie> _newMovies = [];
  String? _error;

  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get newMovies => _newMovies;
  String? get error => _error;
  bool get isLoading => _popularMovies.isEmpty && _newMovies.isEmpty && _error == null;

  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '91e85ac434bf4d595a5f19cb4bd69ce3';
  final String _accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5MWU4NWFjNDM0YmY0ZDU5NWE1ZjE5Y2I0YmQ2OWNlMyIsIm5iZiI6MTc1MjgwNzI1My42MjUsInN1YiI6IjY4NzliNzU1NGQ3N2EwNDhlNDM4YzllZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.bmrwYVLDBCDDmpdzt4Qok2PG9TQNmDZY9r5VqknYdgc';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  MovieProvider() {
    fetchPopularMovies();
    fetchNewMovies();
  }

  Future<void> fetchPopularMovies() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?language=es-ES'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );
      print('Respuesta fetchPopularMovies: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _popularMovies = (data['results'] as List)
            .map((json) => Movie.fromJson(json, isSeries: false))
            .toList();
        _error = null;
      } else {
        _error = 'Error al cargar películas populares: ${response.statusCode}';
        print('Error en fetchPopularMovies: ${response.body}');
      }
    } catch (e) {
      _error = 'Error al cargar películas populares: $e';
      print('Excepción en fetchPopularMovies: $e');
    }
    notifyListeners();
  }

  Future<void> fetchNewMovies() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/now_playing?language=es-ES'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );
      print('Respuesta fetchNewMovies: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _newMovies = (data['results'] as List)
            .map((json) => Movie.fromJson(json, isSeries: false))
            .toList();
        _error = null;
      } else {
        _error = 'Error al cargar películas nuevas: ${response.statusCode}';
        print('Error en fetchNewMovies: ${response.body}');
      }
    } catch (e) {
      _error = 'Error al cargar películas nuevas: $e';
      print('Excepción en fetchNewMovies: $e');
    }
    notifyListeners();
  }

  Future<void> fetchMoviesByCategory(String category) async {
    final genreMap = {
      'acción': 28,
      'aventura': 12,
      'comedia': 35,
      'drama': 18,
      'ciencia ficción': 878,
      'fantasía': 14,
      'terror': 27,
      'misterio': 9648,
      'romance': 10749,
      'documental': 99,
      'animación': 16,
      'familiar': 10751,
    };

    final genreId = genreMap[category.toLowerCase()];
    if (genreId == null) {
      _error = 'Categoría no válida: $category';
      notifyListeners();
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await http.get(
        Uri.parse('$_baseUrl/discover/movie?language=es-ES&with_genres=$genreId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );
      print('Respuesta fetchMoviesByCategory: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _popularMovies = (data['results'] as List)
            .map((json) => Movie.fromJson(json, isSeries: false))
            .toList();
        _error = null;
      } else {
        _error = 'Error al cargar películas por categoría: ${response.statusCode}';
        print('Error en fetchMoviesByCategory: ${response.body}');
      }
    } catch (e) {
      _error = 'Error al cargar películas por categoría: $e';
      print('Excepción en fetchMoviesByCategory: $e');
    }
    notifyListeners();
  }
}