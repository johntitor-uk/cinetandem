import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/forum_post.dart';
import '../widgets/custom_button.dart';

class PostDetailScreen extends StatefulWidget {
  final ForumPost post;
  final Function(String, String, String?) onAddComment;
  final Function(String, String) onAddReaction;
  final Function(String) onAchievementCompleted;
  final Function(String) onAddNotification;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.onAddComment,
    required this.onAddReaction,
    required this.onAchievementCompleted,
    required this.onAddNotification,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  String _userNickname = 'CineLover123';
  String _userCountry = 'España';
  String _userPhotoUrl = 'https://via.placeholder.com/150';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNickname = prefs.getString('nickname') ?? 'CineLover123';
      _userCountry = prefs.getString('country') ?? 'España';
      _userPhotoUrl = prefs.getString('photoUrl') ?? 'https://via.placeholder.com/150';
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

  ImageProvider<Object> _getProfileImage(String photoUrl) {
    try {
      if (photoUrl.startsWith('data:image')) {
        return MemoryImage(base64Decode(photoUrl.split(',')[1]));
      }
      return NetworkImage(photoUrl);
    } catch (e) {
      return const NetworkImage('https://via.placeholder.com/150');
    }
  }

  void _showCommentDialog(String postId, String? parentCommentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        title: const Text('Añadir Comentario', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Escribe tu comentario...',
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          CustomButton(
            text: 'Enviar',
            onPressed: () {
              if (_commentController.text.trim().isNotEmpty) {
                widget.onAddComment(widget.post.id, _commentController.text.trim(), parentCommentId);
                _commentController.clear();
                Navigator.pop(context);
                setState(() {});
              }
            },
            backgroundColor: const Color.fromARGB(255, 255, 60, 56),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                          '${widget.post.user} ${_getCountryFlag(widget.post.country)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Nivel ${widget.post.level} • ${widget.post.country}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          _formatTimestamp(widget.post.timestamp),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.content,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildReactionButton(widget.post.id, 'Me gusta', Icons.thumb_up, Colors.blue),
                      _buildReactionButton(widget.post.id, 'Me encanta', Icons.favorite, Colors.red),
                      _buildReactionButton(widget.post.id, 'Wow', Icons.star, Colors.yellow),
                    ],
                  ),
                  CustomButton(
                    text: 'Comentar',
                    onPressed: () => _showCommentDialog(widget.post.id, null),
                    backgroundColor: const Color.fromARGB(255, 255, 60, 56),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Reacciones: ${widget.post.reactions.isEmpty ? "Ninguna" : widget.post.reactions.entries.map((e) => "${e.key}: ${e.value}").join(", ")}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Comentarios (${widget.post.comments.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.post.comments.isEmpty)
                const Center(
                  child: Text(
                    'No hay comentarios aún. ¡Sé el primero!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              else
                for (var comment in widget.post.comments.where((c) => c.parentCommentId == null))
                  _buildComment(context, widget.post.id, comment, 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(String postId, String reaction, IconData icon, Color color) {
    return IconButton(
      icon: Icon(icon, color: color, size: 18),
      onPressed: () => widget.onAddReaction(postId, reaction),
      tooltip: reaction,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildComment(BuildContext context, String postId, ForumComment comment, int indentLevel) {
    final replies = widget.post.comments.where((c) => c.parentCommentId == comment.id).toList();
    final isOwnComment = comment.user == _userNickname;
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * indentLevel, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: isOwnComment ? Colors.deepOrangeAccent : Colors.grey,
                child: isOwnComment
                    ? Image(
                  image: _getProfileImage(_userPhotoUrl),
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 18, color: Colors.white),
                )
                    : const Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${comment.user} ${_getCountryFlag(comment.country)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Nivel ${comment.level} • ${comment.country}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        _formatTimestamp(comment.timestamp),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          _showCommentDialog(postId, comment.id);
                        },
                        child: const Text(
                          'Responder',
                          style: TextStyle(color: Colors.deepOrangeAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          for (var reply in replies) _buildComment(context, postId, reply, indentLevel + 1),
        ],
      ),
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