import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'video_player_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _historyFilter = 'Todas';
  String _watchedFilter = 'Todas';
  String _historySort = 'Más reciente';
  String _watchedSort = 'Más reciente';
  String _historySearchQuery = '';
  String _watchedSearchQuery = '';
  List<Map<String, dynamic>> _historyItems = [];
  List<Map<String, dynamic>> _watchedItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final history = <Map<String, dynamic>>[];
    final watched = <Map<String, dynamic>>[];

    for (var key in keys) {
      if (key.startsWith('progress_')) {
        final title = key.replaceFirst('progress_', '');
        final progress = prefs.getDouble(key) ?? 0.0;
        final category = prefs.getString('category_$title') ?? 'Película';
        final image = prefs.getString('image_$title') ?? 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg';
        final lastPlayed = prefs.getString('last_played_$title') ?? DateTime.now().toIso8601String();
        history.add({
          'title': title,
          'progress': progress,
          'category': category,
          'image': image,
          'lastPlayed': lastPlayed,
        });
      }
      if (key.startsWith('watched_') && prefs.getBool(key) == true) {
        final title = key.replaceFirst('watched_', '');
        final completionDate = prefs.getString('completion_date_$title');
        final category = prefs.getString('category_$title') ?? 'Película';
        final image = prefs.getString('image_$title') ?? 'https://image.tmdb.org/t/p/w500/8riWcADI1ekEiBguVB9vkilhiQm.jpg';
        if (completionDate != null) {
          watched.add({
            'title': title,
            'completionDate': completionDate,
            'category': category,
            'image': image,
          });
        }
      }
    }

    setState(() {
      _historyItems = history;
      _watchedItems = watched;
    });
  }

  Future<void> _removeItem(String title, bool isWatched) async {
    final prefs = await SharedPreferences.getInstance();
    if (isWatched) {
      await prefs.remove('watched_$title');
      await prefs.remove('completion_date_$title');
    } else {
      await prefs.remove('progress_$title');
      await prefs.remove('last_played_$title');
    }
    await prefs.remove('category_$title');
    await prefs.remove('image_$title');
    await _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title eliminado del historial')),
    );
  }

  Future<void> _clearHistory(bool isWatched) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (isWatched && key.startsWith('watched_')) {
        final title = key.replaceFirst('watched_', '');
        await prefs.remove('watched_$title');
        await prefs.remove('completion_date_$title');
        await prefs.remove('category_$title');
        await prefs.remove('image_$title');
      } else if (!isWatched && key.startsWith('progress_')) {
        final title = key.replaceFirst('progress_', '');
        await prefs.remove('progress_$title');
        await prefs.remove('last_played_$title');
        await prefs.remove('category_$title');
        await prefs.remove('image_$title');
      }
    }
    await _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isWatched ? 'Lista de vistos limpiada' : 'Historial limpiado')),
    );
  }

  List<Map<String, dynamic>> _filterAndSortItems(List<Map<String, dynamic>> items, String filter, String sort, String query, bool isWatched) {
    // Filtrar por categoría
    var filteredItems = filter == 'Todas' ? items : items.where((item) => item['category'] == filter).toList();

    // Filtrar por búsqueda
    if (query.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item['title'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    // Ordenar
    if (sort == 'A-Z') {
      filteredItems.sort((a, b) => a['title'].compareTo(b['title']));
    } else if (sort == 'Más reciente') {
      filteredItems.sort((a, b) {
        final dateA = DateTime.parse(isWatched ? a['completionDate'] : a['lastPlayed'] ?? DateTime.now().toIso8601String());
        final dateB = DateTime.parse(isWatched ? b['completionDate'] : b['lastPlayed'] ?? DateTime.now().toIso8601String());
        return dateB.compareTo(dateA);
      });
    } else if (sort == 'Más antiguo') {
      filteredItems.sort((a, b) {
        final dateA = DateTime.parse(isWatched ? a['completionDate'] : a['lastPlayed'] ?? DateTime.now().toIso8601String());
        final dateB = DateTime.parse(isWatched ? b['completionDate'] : b['lastPlayed'] ?? DateTime.now().toIso8601String());
        return dateA.compareTo(dateB);
      });
    }

    return filteredItems;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        elevation: 0,
        title: const Text(
          'Historial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color.fromARGB(255, 255, 60, 56),
          tabs: const [
            Tab(text: 'Historial'),
            Tab(text: 'Vistos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildWatchedTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final filteredItems = _filterAndSortItems(_historyItems, _historyFilter, _historySort, _historySearchQuery, false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar en historial...',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _historySearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
                onPressed: () => _clearHistory(false),
                tooltip: 'Limpiar historial',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _historyFilter,
                  dropdownColor: const Color.fromARGB(255, 10, 10, 31),
                  style: const TextStyle(color: Colors.white),
                  items: ['Todas', 'Película', 'Serie'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _historyFilter = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: _historySort,
                  dropdownColor: const Color.fromARGB(255, 10, 10, 31),
                  style: const TextStyle(color: Colors.white),
                  items: ['Más reciente', 'Más antiguo', 'A-Z'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _historySort = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
            child: Text(
              'No hay elementos en el historial',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        movieTitle: item['title'],
                        category: item['category'],
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item['image'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: item['progress'],
                        backgroundColor: Colors.black54,
                        color: const Color.fromARGB(255, 255, 60, 56),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        onPressed: () => _removeItem(item['title'], false),
                        tooltip: 'Eliminar del historial',
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchedTab() {
    final filteredItems = _filterAndSortItems(_watchedItems, _watchedFilter, _watchedSort, _watchedSearchQuery, true);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar en vistos...',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _watchedSearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
                onPressed: () => _clearHistory(true),
                tooltip: 'Limpiar lista de vistos',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _watchedFilter,
                  dropdownColor: const Color.fromARGB(255, 10, 10, 31),
                  style: const TextStyle(color: Colors.white),
                  items: ['Todas', 'Película', 'Serie'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _watchedFilter = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: _watchedSort,
                  dropdownColor: const Color.fromARGB(255, 10, 10, 31),
                  style: const TextStyle(color: Colors.white),
                  items: ['Más reciente', 'Más antiguo', 'A-Z'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _watchedSort = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
            child: Text(
              'No hay elementos vistos',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final completionDate = DateTime.parse(item['completionDate']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(completionDate);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        movieTitle: item['title'],
                        category: item['category'],
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item['image'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Visto: $formattedDate',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.black54,
                        color: Colors.green,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        onPressed: () => _removeItem(item['title'], true),
                        tooltip: 'Eliminar de vistos',
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}