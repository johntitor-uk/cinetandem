import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class Netfliz extends StatefulWidget {
  const Netfliz({Key? key}) : super(key: key);

  @override
  NetflizState createState() => NetflizState();
}

class NetflizState extends State<Netfliz> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('No se pudo ir a $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    debugPrint('Netfliz: screenWidth=$screenWidth, screenHeight=$screenHeight, isLandscape=$isLandscape');

    final sectionTitles = ['Retro Toons', 'Buscar', 'Próximamente', 'Descargas', 'Más'];

    SliverAppBar sliverAppBar = SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: isLandscape ? screenHeight * 0.35 : screenHeight * 0.45,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF6B00B6), // Púrpura psicodélico
                    Color(0xFF00FFCC), // Turquesa neón
                    Color(0xFFFF2965), // Rosa neón
                    Color(0xFFFFFF00), // Amarillo neón
                    Color(0xFFFF00FF), // Magenta neón
                  ],
                ),
              ),
            ),
            CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w500/6MKr3KgOLMZ4OzkhYsaNJzIKUCP.jpg', // Powerpuff Girls
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white24),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: isLandscape ? screenHeight * 0.06 : 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '¡Powerpuff Girls en Acción!',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: isLandscape ? screenWidth * 0.04 : 20,
                        shadows: [
                          const Shadow(
                            color: Color(0xFFFF2965),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRetroButton(
                        icon: Icons.play_arrow,
                        label: 'Reproducir',
                        color: const Color(0xFFFFA500), // Naranja neón
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función de reproducción no implementada')),
                          );
                        },
                        isLandscape: isLandscape,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(width: 8),
                      _buildRetroButton(
                        icon: Icons.add,
                        label: 'Mi Lista',
                        color: const Color(0xFF00FF00), // Verde lima
                        onPressed: () {},
                        isLandscape: isLandscape,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(width: 8),
                      _buildRetroButton(
                        icon: Icons.info_outline,
                        label: 'Info',
                        color: const Color(0xFFFF69B4), // Rosa neón
                        onPressed: () {},
                        isLandscape: isLandscape,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: isLandscape ? screenHeight * 0.1 : 40,
            color: Colors.deepOrangeAccent,
          ),
          const SizedBox(width: 8),
          Text(
            sectionTitles[selectedIndex],
            style: GoogleFonts.bangers(
              color: Colors.white,
              fontSize: isLandscape ? screenWidth * 0.05 : 24,
              shadows: [
                const Shadow(
                  color: Color(0xFF00FFCC),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    List<Widget> listScreens = [
      StartScreen(),
      const SearchScreen(),
      const SoonScreen(),
      const DownloadScreen(),
      const MoreScreen(),
    ];

    Stack stackOtherViews = Stack(
      children: [
        listScreens.elementAt(selectedIndex),
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: isLandscape ? screenHeight * 0.1 : 40,
                  color: Colors.deepOrangeAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  sectionTitles[selectedIndex],
                  style: GoogleFonts.bangers(
                    color: Colors.white,
                    fontSize: isLandscape ? screenWidth * 0.05 : 24,
                    shadows: [
                      const Shadow(
                        color: Color(0xFF00FFCC),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.github, color: Color(0xFFFFA500), size: 24),
                onPressed: () => _launchURL("https://www.github.com/RodrigoLara05/"),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.youtube, color: Color(0xFFFFA500), size: 24),
                onPressed: () => _launchURL("https://www.youtube.com/CodigoFuente/"),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.linkedin, color: Color(0xFFFFA500), size: 24),
                onPressed: () => _launchURL("https://www.linkedin.com/in/RodrigoLara05/"),
              ),
            ],
          ),
        ),
      ],
    );

    BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
      backgroundColor: const Color(0xFF1C2526),
      selectedFontSize: isLandscape ? screenWidth * 0.03 : 12,
      unselectedFontSize: isLandscape ? screenWidth * 0.03 : 12,
      selectedItemColor: const Color(0xFFFFA500),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          label: "Inicio",
          icon: AnimatedScale(
            scale: selectedIndex == 0 ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: const Icon(Icons.home, size: 28),
          ),
        ),
        BottomNavigationBarItem(
          label: "Buscar",
          icon: AnimatedScale(
            scale: selectedIndex == 1 ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: const Icon(Icons.search, size: 28),
          ),
        ),
        BottomNavigationBarItem(
          label: "Próximamente",
          icon: AnimatedScale(
            scale: selectedIndex == 2 ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: const Icon(Icons.play_circle_filled, size: 28),
          ),
        ),
        BottomNavigationBarItem(
          label: "Descargas",
          icon: AnimatedScale(
            scale: selectedIndex == 3 ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: const Icon(Icons.file_download, size: 28),
          ),
        ),
        BottomNavigationBarItem(
          label: "Más",
          icon: AnimatedScale(
            scale: selectedIndex == 4 ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: const Icon(Icons.view_headline, size: 28),
          ),
        ),
      ],
      currentIndex: selectedIndex,
      onTap: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1C2526),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 2.0,
            colors: [
              Color(0xFF6B00B6),
              Color(0xFF00FFCC),
              Color(0xFF1C2526),
              Color(0xFFFFFF00),
            ],
          ),
        ),
        child: selectedIndex == 0
            ? CustomScrollView(
          slivers: [
            sliverAppBar,
            SliverToBoxAdapter(child: StartScreen()),
          ],
        )
            : stackOtherViews,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _buildRetroButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isLandscape,
    required double screenWidth,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          shadowColor: Colors.black45,
          elevation: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: isLandscape ? screenWidth * 0.04 : 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: isLandscape ? screenWidth * 0.025 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartScreen extends StatefulWidget {
  StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String _selectedCategory = 'Todos'; // Categoría seleccionada por defecto

  // Definición de categorías originales
  final List<Map<String, dynamic>> originalCategories = [
    {
      'title': 'Clásicos de los 90',
      'shows': [
        {
          'title': 'Powerpuff Girls',
          'image': 'https://image.tmdb.org/t/p/w500/6MKr3KgOLMZ4OzkhYsaNJzIKUCP.jpg',
        },
        {
          'title': 'Animaniacs',
          'image': 'https://image.tmdb.org/t/p/w500/yM0Q4Kz2nk4AiF3QcdNqC1a3r2A.jpg',
        },
      ],
    },
    {
      'title': 'Hanna-Barbera Hits',
      'shows': [
        {
          'title': 'Scooby-Doo',
          'image': 'https://image.tmdb.org/t/p/w500/1n5VUhSCS7kWnS7Eyq8bPr9R2ud.jpg',
        },
        {
          'title': 'The Flintstones',
          'image': 'https://image.tmdb.org/t/p/w500/2MepN4W2F3e6qW6dM3uG0mP7i6A.jpg',
        },
      ],
    },
    {
      'title': 'Nickelodeon Nostalgia',
      'shows': [
        {
          'title': 'Rugrats',
          'image': 'https://image.tmdb.org/t/p/w500/6D7uKBmpkJ6jM28r3O7W3R5sW9B.jpg',
        },
        {
          'title': 'Hey Arnold!',
          'image': 'https://image.tmdb.org/t/p/w500/8k8cA4QbY3bI2eHyX7q0Z4o3j5b.jpg',
        },
      ],
    },
  ];

  // Definición de categorías del carrusel con colores de branding
  final List<Map<String, dynamic>> carouselCategories = [
    {
      'name': 'Todos',
      'color': Colors.white,
      'textColor': Colors.black,
    },
    {
      'name': 'Nickelodeon',
      'color': Color(0xFFFF6200), // Naranja
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'Rugrats',
          'image': 'https://image.tmdb.org/t/p/w500/6D7uKBmpkJ6jM28r3O7W3R5sW9B.jpg',
        },
        {
          'title': 'Hey Arnold!',
          'image': 'https://image.tmdb.org/t/p/w500/8k8cA4QbY3bI2eHyX7q0Z4o3j5b.jpg',
        },
        {
          'title': 'SpongeBob SquarePants',
          'image': 'https://image.tmdb.org/t/p/w500/2mQv1rPgLJ1MLR8f2X0g5a1ULQ0.jpg',
        },
      ],
    },
    {
      'name': 'Fox Kids',
      'color': Color(0xFF00A1D6), // Azul
      'textColor': Colors.black,
      'shows': [
        {
          'title': 'Animaniacs',
          'image': 'https://image.tmdb.org/t/p/w500/yM0Q4Kz2nk4AiF3QcdNqC1a3r2A.jpg',
        },
        {
          'title': 'Tiny Toon Adventures',
          'image': 'https://image.tmdb.org/t/p/w500/9g9g9g9g9g9g9g9g9g9g9g9g9g9.jpg', // Placeholder, reemplazar
        },
      ],
    },
    {
      'name': 'Cartoon Network',
      'color': Color(0xFF000000), // Negro
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'Powerpuff Girls',
          'image': 'https://image.tmdb.org/t/p/w500/6MKr3KgOLMZ4OzkhYsaNJzIKUCP.jpg',
        },
        {
          'title': 'Dexter\'s Laboratory',
          'image': 'https://image.tmdb.org/t/p/w500/8a8q3q3q3q3q3q3q3q3q3q3q3q3.jpg', // Placeholder, reemplazar
        },
      ],
    },
    {
      'name': 'Hanna-Barbera',
      'color': Color(0xFF6B7280), // Gris azulado
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'Scooby-Doo',
          'image': 'https://image.tmdb.org/t/p/w500/1n5VUhSCS7kWnS7Eyq8bPr9R2ud.jpg',
        },
        {
          'title': 'The Flintstones',
          'image': 'https://image.tmdb.org/t/p/w500/2MepN4W2F3e6qW6dM3uG0mP7i6A.jpg',
        },
      ],
    },
    {
      'name': 'Disney',
      'color': Color(0xFF003087), // Azul Disney
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'DuckTales',
          'image': 'https://image.tmdb.org/t/p/w500/6V94jN8Dkw6A2N3T5WNVIvM8V7C.jpg',
        },
        {
          'title': 'Kim Possible',
          'image': 'https://image.tmdb.org/t/p/w500/2j6j6j6j6j6j6j6j6j6j6j6j6j6.jpg', // Placeholder, reemplazar
        },
      ],
    },
    {
      'name': 'Warner Channel',
      'color': Color(0xFFD4A017), // Dorado
      'textColor': Colors.black,
      'shows': [
        {
          'title': 'Looney Tunes',
          'image': 'https://image.tmdb.org/t/p/w500/5b5b5b5b5b5b5b5b5b5b5b5b5b5.jpg', // Placeholder, reemplazar
        },
        {
          'title': 'Batman: The Animated Series',
          'image': 'https://image.tmdb.org/t/p/w500/6b6b6b6b6b6b6b6b6b6b6b6b6b6.jpg', // Placeholder, reemplazar
        },
      ],
    },
    {
      'name': 'Marvel',
      'color': Color(0xFFED1D24), // Rojo
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'X-Men: The Animated Series',
          'image': 'https://image.tmdb.org/t/p/w500/4c4c4c4c4c4c4c4c4c4c4c4c4c4.jpg', // Placeholder, reemplazar
        },
        {
          'title': 'Spider-Man: The Animated Series',
          'image': 'https://image.tmdb.org/t/p/w500/3d3d3d3d3d3d3d3d3d3d3d3d3d3.jpg', // Placeholder, reemplazar
        },
      ],
    },
    {
      'name': 'Otros',
      'color': Color(0xFF6B7280), // Gris neutro
      'textColor': Colors.white,
      'shows': [
        {
          'title': 'The Simpsons',
          'image': 'https://image.tmdb.org/t/p/w500/yTZQkSsxUFJZJu8Trc4j1ELo1I.jpg',
        },
        {
          'title': 'Ren & Stimpy',
          'image': 'https://image.tmdb.org/t/p/w500/1f1f1f1f1f1f1f1f1f1f1f1f1f1.jpg', // Placeholder, reemplazar
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carrusel de categorías
          SizedBox(
            height: isLandscape ? 60 : 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: carouselCategories.length,
              itemBuilder: (context, index) {
                final category = carouselCategories[index];
                final isSelected = _selectedCategory == category['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category['name'];
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? category['color'] : category['color'].withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white, width: isSelected ? 2 : 1),
                      ),
                      shadowColor: Colors.black45,
                      elevation: isSelected ? 6 : 2,
                    ),
                    child: Text(
                      category['name'],
                      style: GoogleFonts.bangers(
                        color: category['textColor'],
                        fontSize: isLandscape ? screenWidth * 0.035 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Contenido según la categoría seleccionada
          if (_selectedCategory == 'Todos')
            ...originalCategories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['title'],
                    style: GoogleFonts.bangers(
                      color: Colors.white,
                      fontSize: isLandscape ? screenWidth * 0.05 : 24,
                      shadows: [
                        const Shadow(
                          color: Color(0xFFFF69B4),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: isLandscape ? 180 : 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: category['shows'].length,
                      itemBuilder: (context, index) {
                        final show = category['shows'][index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Seleccionado: ${show['title']}')),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.elasticOut,
                              width: isLandscape ? screenWidth * 0.25 : 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: show['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fadeInDuration: const Duration(milliseconds: 150),
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        color: Colors.black87,
                                        child: Text(
                                          show['title'],
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: isLandscape ? screenWidth * 0.025 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList()
          else
          // Mostrar caricaturas de la categoría seleccionada
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory,
                  style: GoogleFonts.bangers(
                    color: Colors.white,
                    fontSize: isLandscape ? screenWidth * 0.05 : 24,
                    shadows: [
                      const Shadow(
                        color: Color(0xFFFF69B4),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: isLandscape ? 180 : 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: carouselCategories
                        .firstWhere((cat) => cat['name'] == _selectedCategory)['shows']
                        .length,
                    itemBuilder: (context, index) {
                      final show = carouselCategories
                          .firstWhere((cat) => cat['name'] == _selectedCategory)['shows'][index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Seleccionado: ${show['title']}')),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                            width: isLandscape ? screenWidth * 0.25 : 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: show['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fadeInDuration: const Duration(milliseconds: 150),
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      color: Colors.black87,
                                      child: Text(
                                        show['title'],
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: isLandscape ? screenWidth * 0.025 : 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          'Pantalla de Búsqueda (implementar contenido)',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Color(0xFF00FFCC),
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoonScreen extends StatelessWidget {
  const SoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          'Pantalla de Próximamente (implementar contenido)',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Color(0xFF00FFCC),
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          'Pantalla de Descargas (implementar contenido)',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Color(0xFF00FFCC),
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          'Pantalla de Más (implementar contenido)',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Color(0xFF00FFCC),
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}