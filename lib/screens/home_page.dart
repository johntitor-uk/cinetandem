import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flip_card/flip_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/movie.dart';
import '../models/movie_banner.dart';
import '../utils/favorites_manager.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/forum_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/sync_chat_screen.dart';
import '../screens/history_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../widgets/custom_button.dart';
import '../providers/movie_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isTopBarVisible = true;
  bool _isBottomBarVisible = true;
  double _lastOffset = 0.0;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _activeCardKey;
  DateTime? _lastClickTime;
  final Duration _clickInterval = const Duration(milliseconds: 300);
  final Map<String, List<GlobalKey<FlipCardState>>> _flipCardKeysByCategory = {
    'Populares': [],
    'Recomendadas': [],
    'Nuevas': [],
    'Acción': [],
    'Aventura': [],
    'Comedia': [],
    'Drama': [],
  };

  // User data
  String _nickname = "CineLover123";
  String _fullName = "Juan Pérez";
  int _achievementsCount = 42;
  int _userLevel = 7;
  List<String> _completedAchievements = [];
  List<Map<String, String>> _notifications = [];
  bool _isSettingsExpanded = false;

  static final _customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      maxNrOfCacheObjects: 200,
      stalePeriod: const Duration(days: 7),
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final isScrollingDown = offset > _lastOffset && offset > 20.0;
    final isScrollingUp = offset < _lastOffset && offset <= _lastOffset - 20.0;

    if (isScrollingDown && (_isTopBarVisible || _isBottomBarVisible)) {
      setState(() {
        _isTopBarVisible = false;
        _isBottomBarVisible = false;
      });
    } else if (isScrollingUp && (!_isTopBarVisible || !_isBottomBarVisible)) {
      setState(() {
        _isTopBarVisible = true;
        _isBottomBarVisible = true;
      });
    }
    _lastOffset = offset;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('nickname') ?? "CineLover123";
      _fullName = prefs.getString('fullName') ?? "Juan Pérez";
      _userLevel = prefs.getInt('userLevel') ?? 7;
      _achievementsCount = prefs.getInt('achievementsCount') ?? 42;
      _completedAchievements = prefs.getStringList('completedAchievements') ?? [];
      _notifications = (prefs.getStringList('notifications') ?? [])
          .map((e) => {'message': e})
          .toList();
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('nickname', _nickname),
      prefs.setString('fullName', _fullName),
      prefs.setInt('userLevel', _userLevel),
      prefs.setInt('achievementsCount', _achievementsCount),
      prefs.setStringList('completedAchievements', _completedAchievements),
      prefs.setStringList('notifications', _notifications.map((e) => e['message']!).toList()),
    ]);
  }

  void _addNotification(String message) {
    setState(() {
      if (_notifications.length < 99) {
        _notifications.add({'message': message});
        _saveUserData();
      }
    });
  }

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
      _saveUserData();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _nickname = "CineLover123";
      _fullName = "Juan Pérez";
      _userLevel = 7;
      _achievementsCount = 42;
      _completedAchievements = [];
      _notifications = [];
    });
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await Future.wait([
      _loadUserData(),
      Provider.of<MovieProvider>(context, listen: false).fetchPopularMovies(),
      Provider.of<MovieProvider>(context, listen: false).fetchNewMovies(),
    ]);
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SyncChatScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<String>(
            future: SharedPreferences.getInstance()
                .then((prefs) => prefs.getString('photoUrl') ?? 'https://via.placeholder.com/150'),
            builder: (context, snapshot) {
              ImageProvider<Object> imageProvider;
              if (snapshot.hasData && snapshot.data!.startsWith('data:image')) {
                final base64String = snapshot.data!.split(',')[1];
                final bytes = base64Decode(base64String);
                imageProvider = MemoryImage(bytes);
              } else {
                imageProvider = NetworkImage(snapshot.data ?? 'https://via.placeholder.com/150');
              }
              return UserAccountsDrawerHeader(
                accountName: Row(
                  children: [
                    Text(
                      _nickname,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_userLevel >= 10)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.verified, color: Colors.blue, size: 20),
                      ),
                  ],
                ),
                accountEmail: Text(
                  _fullName,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: imageProvider,
                ),
                otherAccountsPictures: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(
                                notifications: _notifications,
                                onClear: _clearNotifications,
                              ),
                            ),
                          );
                        },
                      ),
                      if (_notifications.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _notifications.length.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.white),
                    onPressed: () async {
                      await _logout();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesión cerrada')),
                        );
                      }
                    },
                    tooltip: 'Cerrar sesión',
                  ),
                ],
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 10, 10, 31),
                ),
                otherAccountsPicturesSize: const Size.square(40),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Logros: $_achievementsCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Nivel: $_userLevel',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, thickness: 1),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.white70),
            title: const Text('Categorías', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: const Text('Historial', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum, color: Colors.white70),
            title: const Text('Foro', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumScreen(
                    onAchievementCompleted: _completeAchievement,
                    onAddNotification: _addNotification,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.white70),
            title: const Text('Favoritos', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble, color: Colors.white70),
            title: const Text('Chat Global', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SyncChatScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.white70),
            title: const Text('Logros', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AchievementsScreen(
                    completedAchievements: _completedAchievements,
                    onAchievementCompleted: _completeAchievement,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white70),
            title: const Text('Notificaciones', style: TextStyle(color: Colors.white)),
            trailing: _notifications.isNotEmpty
                ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _notifications.length.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(
                    notifications: _notifications,
                    onClear: _clearNotifications,
                  ),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text('Configuraciones y soporte', style: TextStyle(color: Colors.white)),
            initiallyExpanded: _isSettingsExpanded,
            onExpansionChanged: (expanded) => setState(() => _isSettingsExpanded = expanded),
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: const Text('Configuraciones del perfil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileSettingsScreen(
                        onAddNotification: _addNotification,
                        onAchievementCompleted: _completeAchievement,
                      ),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
              ListTile(
                leading: const Icon(Icons.movie, color: Colors.white70),
                title: const Text('Pide tu película', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pide tu película no implementada.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.white70),
                title: const Text('Reportar problemas', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reportar problemas no implementado.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            color: const Color.fromARGB(255, 255, 60, 56),
            backgroundColor: const Color.fromARGB(255, 10, 10, 31),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
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
                    child: Column(
                      children: [
                        SizedBox(height: _isTopBarVisible ? kToolbarHeight + MediaQuery.of(context).padding.top : 0),
                        OptimizedBanner(
                          cacheManager: _customCacheManager,
                          onAddNotification: _addNotification,
                          onCompleteAchievement: _completeAchievement,
                        ),
                        Consumer<MovieProvider>(
                          builder: (context, movieProvider, child) {
                            if (movieProvider.isLoading) {
                              return const SizedBox(
                                height: 300,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (movieProvider.error != null) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        movieProvider.error!,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 16),
                                      CustomButton(
                                        text: 'Reintentar',
                                        onPressed: () {
                                          movieProvider.fetchPopularMovies();
                                          movieProvider.fetchNewMovies();
                                        },
                                        backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                                        textColor: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (movieProvider.popularMovies.isEmpty && movieProvider.newMovies.isEmpty) {
                              return const SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    'No hay películas disponibles',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }

                            final popularMovies = movieProvider.popularMovies
                                .where((movie) => movie.rating >= 8.0)
                                .toList()
                              ..sort((a, b) => b.rating.compareTo(a.rating));
                            final recommendedMovies = movieProvider.popularMovies
                                .where((movie) => movie.rating >= 7.5)
                                .toList()
                              ..shuffle();
                            final newMovies = movieProvider.newMovies
                                .where((movie) {
                              final releaseDate = DateTime.tryParse(movie.releaseDate);
                              return releaseDate != null && releaseDate.year >= 2023;
                            })
                                .toList()
                              ..sort((a, b) =>
                              DateTime.tryParse(b.releaseDate)?.compareTo(
                                  DateTime.tryParse(a.releaseDate) ?? DateTime.now()) ??
                                  0);
                            final actionMovies = movieProvider.popularMovies
                                .where((movie) => movie.category.toLowerCase() == 'acción')
                                .toList();
                            final adventureMovies = movieProvider.popularMovies
                                .where((movie) => movie.category.toLowerCase() == 'aventura')
                                .toList();
                            final comedyMovies = movieProvider.popularMovies
                                .where((movie) => movie.category.toLowerCase() == 'comedia')
                                .toList();
                            final dramaMovies = movieProvider.popularMovies
                                .where((movie) => movie.category.toLowerCase() == 'drama')
                                .toList();

                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildSection("🔥 Populares", popularMovies.take(10).toList(), 'Populares'),
                                _buildSection(
                                    "🎯 Recomendadas para ti", recommendedMovies.take(10).toList(), 'Recomendadas'),
                                _buildSection("🆕 Nuevas en CineTandem", newMovies.take(10).toList(), 'Nuevas'),
                                _buildSection("💥 Acción", actionMovies.take(10).toList(), 'Acción'),
                                _buildSection("🌍 Aventura", adventureMovies.take(10).toList(), 'Aventura'),
                                _buildSection("😂 Comedia", comedyMovies.take(10).toList(), 'Comedia'),
                                _buildSection("🎭 Drama", dramaMovies.take(10).toList(), 'Drama'),
                                SizedBox(
                                    height: _isBottomBarVisible
                                        ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 16
                                        : 16),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isTopBarVisible ? 0 : -(kToolbarHeight + MediaQuery.of(context).padding.top + 20),
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isTopBarVisible ? 1.0 : 0.0,
                child: Container(
                  height: kToolbarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 10, 10, 31),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                        tooltip: 'Menú',
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, size: 24, color: Colors.deepOrangeAccent),
                          SizedBox(width: 8),
                          Text(
                            'CineTandem',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white, size: 28),
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: CustomSearchDelegate(
                              selectedCategory: 'all',
                              getMoviesForCategory: (category) {
                                final movieProvider = Provider.of<MovieProvider>(context, listen: false);
                                return [
                                  ...movieProvider.popularMovies,
                                  ...movieProvider.newMovies,
                                ];
                              },
                              cacheManager: _customCacheManager,
                            ),
                          );
                        },
                        tooltip: 'Buscar',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isBottomBarVisible ? 0 : -kBottomNavigationBarHeight,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isBottomBarVisible ? 1.0 : 0.0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 10, 10, 31),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: const Color.fromARGB(255, 10, 10, 31),
                    selectedItemColor: Colors.deepOrangeAccent,
                    unselectedItemColor: Colors.white70,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.home, size: 24), label: ''),
                      BottomNavigationBarItem(icon: Icon(Icons.category, size: 24), label: ''),
                      BottomNavigationBarItem(icon: Icon(Icons.favorite, size: 24), label: ''),
                      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble, size: 24), label: ''),
                    ],
                    elevation: 0,
                    selectedIconTheme: const IconThemeData(size: 28, opacity: 1.0),
                    unselectedIconTheme: const IconThemeData(size: 24, opacity: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Movie> movies, String category) {
    if (_flipCardKeysByCategory[category]!.isEmpty) {
      _flipCardKeysByCategory[category] = List.generate(movies.length, (_) => GlobalKey<FlipCardState>());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (movies.length > 5)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                    );
                  },
                  child: const Text(
                    'Ver más',
                    style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            cacheExtent: 1500.0,
            itemCount: movies.length,
            itemExtent: 150,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final cardKey = '${category}_$index';
              final flipCardKey = _flipCardKeysByCategory[category]![index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    if (_lastClickTime != null && now.difference(_lastClickTime!) < _clickInterval) {
                      return;
                    }
                    _lastClickTime = now;

                    if (_activeCardKey != null && _activeCardKey != cardKey) {
                      final activeCategory = _activeCardKey!.split('_')[0];
                      final activeIndex = int.parse(_activeCardKey!.split('_')[1]);
                      final activeFlipCardKey = _flipCardKeysByCategory[activeCategory]![activeIndex];
                      if (activeFlipCardKey.currentState != null && !activeFlipCardKey.currentState!.isFront) {
                        activeFlipCardKey.currentState!.toggleCard();
                        await Future.delayed(const Duration(milliseconds: 300));
                      }
                    }
                    setState(() => _activeCardKey = cardKey);
                    flipCardKey.currentState!.toggleCard();
                  },
                  child: SizedBox(
                    width: 140,
                    child: FlipCard(
                      key: flipCardKey,
                      flipOnTouch: false,
                      front: Hero(
                        tag: 'movie_${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: movie.imageUrl,
                            width: 140,
                            height: 210,
                            fit: BoxFit.cover,
                            memCacheWidth: 280,
                            cacheManager: _customCacheManager,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepOrangeAccent,
                                )),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image, size: 64, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      back: Container(
                        width: 140,
                        height: 210,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color.fromARGB(255, 255, 60, 56), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  children: [
                                    Text(
                                      movie.title,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 60, 56),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Estreno: ${movie.releaseDate}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.description.isNotEmpty ? movie.description : 'Sin descripción disponible',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star, color: Colors.yellow[700], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          movie.rating.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Actores: ${movie.actors.isNotEmpty ? movie.actors.join(', ') : 'Desconocido'}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: CustomButton(
                                    key: ValueKey('section_${category}_$index'),
                                    text: 'Ver',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailScreen(movie: movie),
                                        ),
                                      );
                                      _completeAchievement('Ver 10 películas');
                                    },
                                    backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                                    textColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FutureBuilder<bool>(
                                    future: FavoritesManager.isFavorite(movie.title),
                                    initialData: false,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting &&
                                          !snapshot.hasData) {
                                        return const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                        );
                                      }
                                      final isFavorite = snapshot.data ?? false;
                                      return IconButton(
                                        key: ValueKey('favorite_${category}_$index'),
                                        icon: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorite
                                              ? const Color.fromARGB(255, 255, 60, 56)
                                              : Colors.grey[400],
                                          size: 24,
                                        ),
                                        onPressed: () async {
                                          if (isFavorite) {
                                            await FavoritesManager.removeFavorite(movie.title);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Eliminado de favoritos: ${movie.title}'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } else {
                                            await FavoritesManager.addFavorite(movie.title);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Agregado a favoritos: ${movie.title}'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                              _completeAchievement('Añadir 10 favoritos');
                                            }
                                          }
                                          if (mounted) setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _completeAchievement(String achievement) {
    if (!_completedAchievements.contains(achievement)) {
      setState(() {
        _completedAchievements.add(achievement);
        _achievementsCount = _completedAchievements.length;
        _addNotification('¡Nuevo logro desbloqueado: $achievement!');
        if (_achievementsCount % 50 == 0 && _userLevel < 10) {
          _userLevel++;
          _addNotification('¡Subiste al nivel $_userLevel!');
        }
        _saveUserData();
      });
    }
  }
}

class OptimizedBanner extends StatefulWidget {
  final CacheManager cacheManager;
  final Function(String) onAddNotification;
  final Function(String) onCompleteAchievement;

  const OptimizedBanner({
    super.key,
    required this.cacheManager,
    required this.onAddNotification,
    required this.onCompleteAchievement,
  });

  @override
  State<OptimizedBanner> createState() => _OptimizedBannerState();
}

class _OptimizedBannerState extends State<OptimizedBanner> {
  final ValueNotifier<List<MovieBanner>> _banners = ValueNotifier([]);
  int _currentBannerIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _banners.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    await movieProvider.fetchNewMovies();
    if (mounted) {
      final newBanners = movieProvider.newMovies
          .where((movie) {
        final releaseDate = DateTime.tryParse(movie.releaseDate);
        return releaseDate != null && releaseDate.year >= 2023;
      })
          .take(5)
          .map((movie) => MovieBanner(
        imageUrl: movie.imageUrl,
        title: movie.title,
        description: movie.description.isNotEmpty ? movie.description : 'Sin descripción disponible',
        rating: movie.rating,
        actors: movie.actors,
        category: movie.category,
        releaseDate: movie.releaseDate,
      ))
          .toList();
      _banners.value = newBanners;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchBanners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MovieBanner>>(
      valueListenable: _banners,
      builder: (context, banners, child) {
        if (banners.isEmpty) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Container(
          padding: const EdgeInsets.only(top: 8),
          color: const Color.fromARGB(255, 10, 10, 31),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: BannerCarousel(
                  banners: banners,
                  cacheManager: widget.cacheManager,
                  onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                ),
              ),
              BannerMetadata(
                key: const ValueKey('banner_metadata'),
                banner: banners[_currentBannerIndex],
                onViewPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(
                        movie: Movie(
                          id: 0,
                          imageUrl: banners[_currentBannerIndex].imageUrl,
                          title: banners[_currentBannerIndex].title,
                          description: banners[_currentBannerIndex].description.isNotEmpty
                              ? banners[_currentBannerIndex].description
                              : 'Sin descripción disponible',
                          rating: banners[_currentBannerIndex].rating,
                          actors: banners[_currentBannerIndex].actors,
                          category: banners[_currentBannerIndex].category ?? 'Desconocida',
                          releaseDate: banners[_currentBannerIndex].releaseDate,
                        ),
                      ),
                    ),
                  );
                  widget.onCompleteAchievement('Ver 10 películas');
                },
                onFavoriteToggled: (isFavorite) async {
                  if (isFavorite) {
                    await FavoritesManager.removeFavorite(banners[_currentBannerIndex].title);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Eliminado de favoritos: ${banners[_currentBannerIndex].title}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    await FavoritesManager.addFavorite(banners[_currentBannerIndex].title);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Agregado a favoritos: ${banners[_currentBannerIndex].title}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      widget.onCompleteAchievement('Añadir 10 favoritos');
                      widget.onAddNotification('¡Añadido a favoritos: ${banners[_currentBannerIndex].title}!');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<MovieBanner> banners;
  final CacheManager cacheManager;
  final Function(int) onPageChanged;

  const BannerCarousel({
    super.key,
    required this.banners,
    required this.cacheManager,
    required this.onPageChanged,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;
  Timer? _timer;
  bool _hasPreloadedImages = false;

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPreloadedImages) {
      _preloadImages();
      _hasPreloadedImages = true;
    }
  }

  void _preloadImages() {
    for (var banner in widget.banners) {
      precacheImage(
        CachedNetworkImageProvider(banner.imageUrl, cacheManager: widget.cacheManager),
        context,
      );
    }
  }

  void _startCarouselTimer() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        int nextPage = (_currentIndex + 1) % widget.banners.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentIndex = nextPage);
        widget.onPageChanged(nextPage);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: 260,
              viewportFraction: 1.0,
              autoPlay: false,
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
                widget.onPageChanged(index);
              },
            ),
            items: widget.banners.map((banner) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 400,
                  cacheManager: widget.cacheManager,
                  placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrangeAccent,
                      )),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.white24),
                  ),
                ),
              );
            }).toList(),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index ? Colors.deepOrangeAccent : Colors.white38,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class BannerMetadata extends StatefulWidget {
  final MovieBanner banner;
  final VoidCallback onViewPressed;
  final Function(bool) onFavoriteToggled;

  const BannerMetadata({
    super.key,
    required this.banner,
    required this.onViewPressed,
    required this.onFavoriteToggled,
  });

  @override
  State<BannerMetadata> createState() => _BannerMetadataState();
}

class _BannerMetadataState extends State<BannerMetadata> {
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  @override
  void didUpdateWidget(BannerMetadata oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.title != widget.banner.title) {
      _loadFavoriteStatus();
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await FavoritesManager.isFavorite(widget.banner.title);
    if (mounted) {
      setState(() => _isFavorite = isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 10, 10, 31),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.banner.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star, color: Colors.yellow[700], size: 16),
              const SizedBox(width: 4),
              Text(
                widget.banner.rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Text(
                'Estreno: ${widget.banner.releaseDate}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.banner.description.isNotEmpty ? widget.banner.description : 'Sin descripción disponible',
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actores: ${widget.banner.actors.isNotEmpty ? widget.banner.actors.join(', ') : 'Desconocido'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                key: const ValueKey('banner_view_button'),
                text: 'Ver',
                onPressed: widget.onViewPressed,
                backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                textColor: Colors.white,
              ),
              const SizedBox(width: 8),
              _isFavorite == null
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              )
                  : IconButton(
                key: const ValueKey('banner_favorite_button'),
                icon: Icon(
                  _isFavorite! ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite! ? const Color.fromARGB(255, 255, 60, 56) : Colors.grey[400],
                  size: 24,
                ),
                onPressed: () async {
                  await widget.onFavoriteToggled(_isFavorite!);
                  if (mounted) {
                    setState(() => _isFavorite = !_isFavorite!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}