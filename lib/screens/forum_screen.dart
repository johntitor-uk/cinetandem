import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/forum_post.dart';
import '../widgets/custom_button.dart';
import 'post_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  final Function(String) onAchievementCompleted;
  final Function(String) onAddNotification;

  const ForumScreen({
    super.key,
    required this.onAchievementCompleted,
    required this.onAddNotification,
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _postTitleController = TextEditingController();
  final TextEditingController _postContentController = TextEditingController();
  final List<ForumPost> _posts = [];
  String _userNickname = 'CineLover123';
  String _userCountry = 'España';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _posts.addAll([
      ForumPost(
        id: '1',
        user: 'CineLover123',
        level: 5,
        country: 'España',
        title: 'Opinión sobre "La Leyenda del Oro"',
        content: 'Acabo de ver "La Leyenda del Oro" y la cinematografía es espectacular. ¿Qué opinan de la escena final? ¡Quiero leer sus teorías!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        comments: [
          ForumComment(
            id: 'c1',
            user: 'MovieFan456',
            level: 3,
            country: 'México',
            content: '¡Totalmente de acuerdo! La escena final me dejó sin palabras. Creo que el director quiso simbolizar la libertad.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        reactions: {'Me gusta': 5, 'Me encanta': 2},
      ),
      ForumPost(
        id: '2',
        user: 'MovieFan456',
        level: 3,
        country: 'México',
        title: '¿Recomiendan "El Guerrero"?',
        content: 'Estoy pensando en ver "El Guerrero". ¿Vale la pena? Escuché que la escena de la batalla es épica, pero quiero sus opiniones.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        reactions: {'Wow': 3},
      ),
    ]);
  }

  @override
  void dispose() {
    _postTitleController.dispose();
    _postContentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNickname = prefs.getString('nickname') ?? 'CineLover123';
      _userCountry = prefs.getString('country') ?? 'España';
    });
  }

  String _getCountryFlag(String country) {
    const Map<String, String> countryFlags = {
      'Argentina': '🇦🇷',
      'Brasil': '🇧🇷',
      'Chile': '🇨🇱',
      'Colombia': '🇨🇴',
      'España': '🇪🇸',
      'México': '🇲🇽',
      'Perú': '🇵🇪',
      'Estados Unidos': '🇺🇸',
      'Otro': '🌍',
    };
    return countryFlags[country] ?? '🌍';
  }

  void _createPost() {
    final String title = _postTitleController.text.trim();
    final String content = _postContentController.text.trim();
    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        _posts.insert(
          0,
          ForumPost(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            user: _userNickname,
            level: 5,
            country: _userCountry,
            title: title,
            content: content,
            timestamp: DateTime.now(),
          ),
        );
        _postTitleController.clear();
        _postContentController.clear();
        widget.onAchievementCompleted('Crear publicación en el foro');
        widget.onAddNotification('¡Publicaste en el foro!');
      });
    }
  }

  void _addComment(String postId, String comment, String? parentCommentId) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.comments.add(
        ForumComment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          user: _userNickname,
          level: 5,
          country: _userCountry,
          content: comment,
          timestamp: DateTime.now(),
          parentCommentId: parentCommentId,
        ),
      );
      widget.onAchievementCompleted('Escribir 3 comentarios');
      widget.onAddNotification('¡Comentaste en una publicación!');
    });
  }

  void _addReaction(String postId, String reaction) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.reactions[reaction] = (post.reactions[reaction] ?? 0) + 1;
      widget.onAchievementCompleted('Dar 10 likes');
      widget.onAddNotification('¡Reaccionaste a una publicación!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foro de CineTandem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        elevation: 4,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _postTitleController,
                      decoration: InputDecoration(
                        hintText: 'Título de tu publicación',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _postContentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu publicación...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: const TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CustomButton(
                        text: 'Publicar',
                        onPressed: _createPost,
                        backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _posts.isEmpty
                ? const Center(
              child: Text(
                'No hay publicaciones aún. ¡Sé el primero en compartir!',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
              ),
            )
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostPreviewCard(context, post);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreviewCard(BuildContext context, ForumPost post) {
    final previewContent = post.content.length > 100 ? '${post.content.substring(0, 100)}...' : post.content;
    return Card(
      color: Colors.black87,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: post,
                onAddComment: _addComment,
                onAddReaction: _addReaction,
                onAchievementCompleted: widget.onAchievementCompleted,
                onAddNotification: widget.onAddNotification,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepOrangeAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${post.user} ${_getCountryFlag(post.country)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Nivel ${post.level} • ${post.country}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                previewContent,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Comentarios: ${post.comments.length} • ${_formatTimestamp(post.timestamp)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildReactionButton(post.id, 'Me gusta', Icons.thumb_up, Colors.blue),
                      _buildReactionButton(post.id, 'Me encanta', Icons.favorite, Colors.red),
                      _buildReactionButton(post.id, 'Wow', Icons.star, Colors.yellow),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Reacciones: ${post.reactions.isEmpty ? "Ninguna" : post.reactions.entries.map((e) => "${e.key}: ${e.value}").join(", ")}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(String postId, String reaction, IconData icon, Color color) {
    return IconButton(
      icon: Icon(icon, color: color, size: 18),
      onPressed: () => _addReaction(postId, reaction),
      tooltip: reaction,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} horas';
    return 'Hace ${difference.inDays} días';
  }
}