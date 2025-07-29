class MovieBanner {
  final String imageUrl;
  final String title;
  final String description;
  final double rating;
  final List<String> actors;
  final String releaseDate;
  final String? category;

  MovieBanner({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.rating,
    required this.actors,
    required this.releaseDate,
    this.category,
  });
}