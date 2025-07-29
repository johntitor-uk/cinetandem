import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../utils/favorites_manager.dart';
import '../widgets/custom_button.dart';
import '../providers/movie_provider.dart';

class MovieDetailScreen extends StatefulWidget {
final Movie movie;

const MovieDetailScreen({super.key, required this.movie});

@override
State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
bool _isFavorite = false;

@override
void initState() {
super.initState();
_checkFavoriteStatus();
}

Future<void> _checkFavoriteStatus() async {
final isFavorite = await FavoritesManager.isFavorite(widget.movie.title);
if (mounted) {
setState(() => _isFavorite = isFavorite);
}
}

Future<void> _toggleFavorite() async {
if (_isFavorite) {
await FavoritesManager.removeFavorite(widget.movie.title);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Eliminado de favoritos: ${widget.movie.title}',
),
),
);
}
} else {
await FavoritesManager.addFavorite(widget.movie.title);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Agregado a favoritos: ${widget.movie.title}',
),
),
);
}
}
if (mounted) {
setState(() => _isFavorite = !_isFavorite);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color.fromARGB(255, 10, 10, 31),
body: CustomScrollView(
slivers: [
SliverAppBar(
expandedHeight: 300.0,
floating: false,
pinned: true,
backgroundColor: const Color.fromARGB(255, 10, 10, 31),
flexibleSpace: FlexibleSpaceBar(
background: CachedNetworkImage(
imageUrl: widget.movie.imageUrl,
fit: BoxFit.cover,
placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white24),
),
),
actions: [
IconButton(
icon: const Icon(Icons.share, color: Colors.white),
onPressed: () {
Share.share(
'Mira esta película: ${widget.movie.title}\nDescripción: ${widget.movie.description}',
);
},
),
IconButton(
icon: Icon(
Icons.favorite,
color: _isFavorite ? const Color.fromARGB(255, 255, 60, 56) : Colors.grey[400],
),
onPressed: _toggleFavorite,
),
],
),
SliverToBoxAdapter(
child: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Color.fromARGB(255, 10, 10, 31),
Color.fromARGB(255, 42, 42, 75),
],
),
),
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
widget.movie.title,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),
Row(
children: [
Icon(Icons.star, color: Colors.yellow[700], size: 20),
const SizedBox(width: 4),
Text(
widget.movie.rating.toString(),
style: const TextStyle(color: Colors.white70, fontSize: 16),
),
const SizedBox(width: 16),
Text(
widget.movie.category,
style: const TextStyle(color: Colors.white70, fontSize: 16),
),
],
),
const SizedBox(height: 8),
Text(
'Estreno: ${widget.movie.releaseDate}',
style: const TextStyle(color: Colors.white70, fontSize: 16),
),
const SizedBox(height: 16),
const Text(
'Descripción',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),
Text(
widget.movie.description.isNotEmpty ? widget.movie.description : 'Sin descripción disponible',
style: const TextStyle(color: Colors.white, fontSize: 16),
),
const SizedBox(height: 16),
const Text(
'Actores',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),
Text(
widget.movie.actors.isNotEmpty ? widget.movie.actors.join(', ') : 'Desconocido',
style: const TextStyle(color: Colors.white, fontSize: 16),
),
const SizedBox(height: 16),
Consumer<MovieProvider>(
builder: (context, movieProvider, child) {
final relatedMovies = movieProvider.popularMovies
    .where((m) => m.category == widget.movie.category && m.id != widget.movie.id)
    .take(5)
    .toList();
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Películas relacionadas',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),
SizedBox(
height: 180,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: relatedMovies.length,
itemBuilder: (context, index) {
final relatedMovie = relatedMovies[index];
return GestureDetector(
onTap: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => MovieDetailScreen(movie: relatedMovie),
),
);
},
child: Padding(
padding: const EdgeInsets.only(right: 8.0),
child: ClipRRect(
borderRadius: BorderRadius.circular(8),
child: CachedNetworkImage(
imageUrl: relatedMovie.imageUrl,
width: 120,
height: 180,
fit: BoxFit.cover,
placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white24),
),
),
),
);
},
),
),
],
);
},
),
const SizedBox(height: 16),
Center(
child: CustomButton(
text: 'Volver',
onPressed: () => Navigator.pop(context),
backgroundColor: const Color.fromARGB(255, 255, 60, 56),
textColor: Colors.white,
),
),
],
),
),
),
],
),
);
}
}
