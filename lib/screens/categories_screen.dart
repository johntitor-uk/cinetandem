import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../utils/favorites_manager.dart';
import '../screens/movie_detail_screen.dart';
import '../widgets/custom_button.dart';
import '../providers/movie_provider.dart';
import '../screens/search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Acción';
  List<String> _exploredCategories = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _appBarAnimationController;
  late Animation<Offset> _appBarSlideAnimation;
  bool _isGridView = false;
  double _bannerOffset = 0.0;
  double _lastOffset = 0.0;
  bool _isAppBarVisible = true;
  final ValueNotifier<Map<String, bool>> _favoritesNotifier = ValueNotifier({});

  static final _customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      maxNrOfCacheObjects: 200,
      stalePeriod: const Duration(days: 7),
    ),
  );

  final List<String> _categories = [
    'Acción',
    'Aventura',
    'Comedia',
    'Drama',
    'Ciencia Ficción',
    'Fantasía',
    'Terror',
    'Misterio',
    'Romance',
    'Documental',
    'Animación',
    'Familiar',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Acción': Icons.local_fire_department,
    'Aventura': Icons.explore,
    'Comedia': Icons.mood,
    'Drama': Icons.theater_comedy,
    'Ciencia Ficción': Icons.rocket_launch,
    'Fantasía': Icons.auto_awesome,
    'Terror': Icons.nightlight_round,
    'Misterio': Icons.warning_amber,
    'Romance': Icons.favorite,
    'Documental': Icons.document_scanner,
    'Animación': Icons.animation,
    'Familiar': Icons.family_restroom,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSelectedCategory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _appBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _scrollController.addListener(_onScroll);
    _initializeFavorites();
    _categories.forEach((category) => _fetchMoviesForCategory(category));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _appBarAnimationController.dispose();
    _scrollController.dispose();
    _favoritesNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCategory = prefs.getString('selected_category') ?? 'Acción';
    });
  }

  Future<void> _saveSelectedCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_category', category);
    if (!_exploredCategories.contains(category)) {
      setState(() {
        _exploredCategories.add(category);
      });
    }
  }

  void _initializeFavorites() async {
    final movies = _getMoviesForCategory(_selectedCategory);
    final favoritesMap = <String, bool>{};
    for (var movie in movies) {
      favoritesMap[movie.title] = await FavoritesManager.isFavorite(movie.title);
    }
    _favoritesNotifier.value = favoritesMap;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if ((offset - _lastOffset).abs() > 10) {
      setState(() {
        _bannerOffset = offset * 0.15;
        if (offset > _lastOffset && offset > 100) {
          if (_isAppBarVisible) {
            _appBarAnimationController.forward();
            _isAppBarVisible = false;
          }
        } else if (offset < _lastOffset) {
          if (!_isAppBarVisible) {
            _appBarAnimationController.reverse();
            _isAppBarVisible = true;
          }
        }
        _lastOffset = offset;
      });
    }
  }

  Future<void> _fetchMoviesForCategory(String category) async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    await movieProvider.fetchMoviesByCategory(category.toLowerCase());
    _initializeFavorites();
    setState(() {});
  }

  List<Movie> _getMoviesForCategory(String category) {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    return [
      ...movieProvider.popularMovies,
      ...movieProvider.newMovies,
    ].where((movie) => movie.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 80),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Consumer<MovieProvider>(
                        builder: (context, movieProvider, child) {
                          final movies = _getMoviesForCategory(_selectedCategory);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryGrid(isLandscape, screenWidth),
                              const SizedBox(height: 24),
                              _buildBanner(isLandscape),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Películas en $_selectedCategory',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isLandscape ? 22 : 18,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (movieProvider.isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (movieProvider.error != null)
                                Center(
                                  child: Text(
                                    movieProvider.error!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                )
                              else if (movies.isEmpty)
                                  const Center(
                                    child: Text(
                                      'No hay películas en esta categoría.',
                                      style: TextStyle(color: Colors.white70, fontSize: 16),
                                    ),
                                  )
                                else
                                  _buildMovieList(movies, isLandscape, screenWidth),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SlideTransition(
                position: _appBarSlideAnimation,
                child: _buildAppBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color.fromARGB(255, 10, 10, 31),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              'Categorías',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.list : Icons.grid_view,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                tooltip: _isGridView ? 'Vista de lista' : 'Vista de mosaico',
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(
                      selectedCategory: _selectedCategory,
                      getMoviesForCategory: _getMoviesForCategory,
                      cacheManager: _customCacheManager,
                    ),
                  );
                },
                tooltip: 'Buscar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(bool isLandscape, double screenWidth) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = isLandscape ? screenWidth * 0.18 : screenWidth * 0.28;
    final buttonHeight = isLandscape ? screenHeight * 0.10 : screenHeight * 0.08;
    final fontSize = isLandscape ? screenWidth * 0.035 : screenWidth * 0.04;
    final iconSize = isLandscape ? screenWidth * 0.05 : screenWidth * 0.05;
    final containerHeight = isLandscape ? screenHeight * 0.22 : screenHeight * 0.16;

    return Container(
      height: containerHeight,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _saveSelectedCategory(category);
                        _initializeFavorites();
                        _animationController.reset();
                        _animationController.forward();
                      });
                      _fetchMoviesForCategory(category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: buttonWidth,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 255, 60, 56),
                            Colors.black87,
                          ],
                        )
                            : null,
                        color: isSelected ? null : Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : const Color.fromARGB(255, 255, 60, 56).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            _categoryIcons[category] ?? Icons.category,
                            color: Colors.white.withOpacity(0.9),
                            size: iconSize,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize,
                                fontFamily: 'Roboto',
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBanner(bool isLandscape) {
    return GestureDetector(
      onTap: () {
        final movieProvider = Provider.of<MovieProvider>(context, listen: false);
        final featuredMovie = movieProvider.popularMovies.isNotEmpty
            ? movieProvider.popularMovies.first
            : null;
        if (featuredMovie != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movie: featuredMovie),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isLandscape ? 28 : 20),
        height: isLandscape ? 200 : 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -_bannerOffset),
              child: CachedNetworkImage(
                imageUrl: Provider.of<MovieProvider>(context).popularMovies.isNotEmpty
                    ? Provider.of<MovieProvider>(context).popularMovies.first.imageUrl
                    : 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: isLandscape ? 230 : 180,
                fadeInDuration: const Duration(milliseconds: 300),
                cacheManager: _customCacheManager,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    Provider.of<MovieProvider>(context).popularMovies.isNotEmpty
                        ? Provider.of<MovieProvider>(context).popularMovies.first.title
                        : 'Destacado: La Leyenda del Oro',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 20 : 16,
                      fontFamily: 'Roboto',
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Provider.of<MovieProvider>(context).popularMovies.isNotEmpty
                        ? (Provider.of<MovieProvider>(context).popularMovies.first.description.isNotEmpty
                        ? Provider.of<MovieProvider>(context).popularMovies.first.description
                        : 'Sin descripción disponible')
                        : 'Una épica aventura en busca de un tesoro perdido.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isLandscape ? 14 : 12,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    text: 'Ver ahora',
                    onPressed: () {
                      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
                      final featuredMovie = movieProvider.popularMovies.isNotEmpty
                          ? movieProvider.popularMovies.first
                          : null;
                      if (featuredMovie != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: featuredMovie),
                          ),
                        );
                      }
                    },
                    backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies, bool isLandscape, double screenWidth) {
    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 5);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _isGridView
          ? GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        cacheExtent: 1000.0,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isLandscape ? 16 : 12,
          mainAxisSpacing: isLandscape ? 16 : 12,
          childAspectRatio: isLandscape ? 0.7 : 0.65,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
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
                        width: double.infinity,
                        height: double.infinity,
                        fadeInDuration: const Duration(milliseconds: 300),
                        cacheManager: _customCacheManager,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 16 : 14,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: isLandscape ? 16 : 14),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toString(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isLandscape ? 14 : 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        cacheExtent: 1000.0,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromARGB(255, 255, 60, 56), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: movie.imageUrl,
                          width: isLandscape ? 180 : 140,
                          height: isLandscape ? 240 : 200,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          cacheManager: _customCacheManager,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLandscape ? 20 : 18,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estreno: ${movie.releaseDate}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isLandscape ? 14 : 12,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.yellow[700], size: isLandscape ? 20 : 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.rating.toString(),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isLandscape ? 16 : 14,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Actores: ${movie.actors.isNotEmpty ? movie.actors.join(', ') : 'Desconocido'}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isLandscape ? 14 : 12,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CustomButton(
                                    text: 'Ver',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailScreen(movie: movie),
                                        ),
                                      );
                                    },
                                    backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                                    textColor: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  ValueListenableBuilder<Map<String, bool>>(
                                    valueListenable: _favoritesNotifier,
                                    builder: (context, favorites, _) {
                                      final isFavorite = favorites[movie.title] ?? false;
                                      return IconButton(
                                        icon: Icon(
                                          Icons.favorite,
                                          color: isFavorite
                                              ? const Color.fromARGB(255, 255, 60, 56)
                                              : Colors.grey,
                                          size: isLandscape ? 28 : 24,
                                        ),
                                        onPressed: () async {
                                          if (isFavorite) {
                                            await FavoritesManager.removeFavorite(movie.title);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Eliminado de favoritos: ${movie.title}'),
                                              ),
                                            );
                                          } else {
                                            await FavoritesManager.addFavorite(movie.title);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Agregado a favoritos: ${movie.title}'),
                                              ),
                                            );
                                          }
                                          final newFavorites = Map<String, bool>.from(_favoritesNotifier.value);
                                          newFavorites[movie.title] = !isFavorite;
                                          _favoritesNotifier.value = newFavorites;
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}