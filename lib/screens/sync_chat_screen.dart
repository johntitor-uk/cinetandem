import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class SyncChatScreen extends StatefulWidget {
  const SyncChatScreen({super.key});

  @override
  State<SyncChatScreen> createState() => _SyncChatScreenState();
}

class _SyncChatScreenState extends State<SyncChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isTyping = ValueNotifier<bool>(false);
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Map<String, dynamic>> _messages = [
    {
      'user': 'CineLover123',
      'country': 'España',
      'message': '¡Esta escena es increíble! ¿Qué opinan?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'reactions': <String, int>{},
      'replyTo': null,
    },
    {
      'user': 'MovieFan456',
      'country': 'México',
      'message': 'Totalmente, el giro de la trama me sorprendió.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      'reactions': <String, int>{},
      'replyTo': null,
    },
  ];
  bool _isMuted = false;
  Map<String, dynamic>? _replyingTo;
  String _userNickname = 'CineLover123';
  String _userCountry = 'España';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  void _sendMessage() {
    final String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({
          'user': _userNickname,
          'country': _userCountry,
          'message': message,
          'timestamp': DateTime.now(),
          'reactions': <String, int>{},
          'replyTo': _replyingTo,
        });
        _listKey.currentState?.insertItem(_messages.length - 1);
        _messageController.clear();
        _replyingTo = null;
        _isTyping.value = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _addReaction(int index, String emoji) {
    setState(() {
      final reactions = _messages[index]['reactions'] as Map<String, int>;
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    });
  }

  void _deleteMessage(int index) {
    if (_messages[index]['user'] == _userNickname) {
      final removedItem = _messages[index];
      setState(() {
        _messages.removeAt(index);
      });
      _listKey.currentState?.removeItem(
        index,
            (context, animation) => _buildMessageWidget(removedItem, animation, removedItem['user'] == _userNickname),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje eliminado')),
      );
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isMuted ? 'Chat silenciado' : 'Chat activado')),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Limpiar chat', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres limpiar todos los mensajes?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final int count = _messages.length;
                for (int i = count - 1; i >= 0; i--) {
                  final removedItem = _messages[i];
                  _messages.removeAt(i);
                  _listKey.currentState?.removeItem(
                    i,
                        (context, animation) => _buildMessageWidget(removedItem, animation, removedItem['user'] == _userNickname),
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat limpiado')),
              );
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showReactionDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Wrap(
          spacing: 8,
          children: ['👍', '👎', '❤️', '😄', '😢', '😡'].map((emoji) {
            return IconButton(
              icon: Text(emoji, style: const TextStyle(fontSize: 24)),
              onPressed: () {
                _addReaction(index, emoji);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 20, 20, 40),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply, color: Colors.white70),
            title: const Text('Responder', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _replyingTo = _messages[index];
              });
              Navigator.pop(context);
            },
          ),
          if (_messages[index]['user'] == _userNickname)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white70),
              title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              onTap: () {
                _deleteMessage(index);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add_reaction, color: Colors.white70),
            title: const Text('Añadir reacción', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showReactionDialog(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(Map<String, dynamic> message, Animation<double> animation, bool isMe) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(_messages.indexOf(message)),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? [
                    Colors.deepOrangeAccent.withOpacity(0.3),
                    Colors.deepOrangeAccent.withOpacity(0.1),
                  ]
                      : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (message['replyTo'] != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Respondiendo a ${message['replyTo']['user']}: ${message['replyTo']['message']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          '${message['user']} ${_getCountryFlag(message['country'])}',
                          style: TextStyle(
                            color: isMe ? Colors.deepOrangeAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['message']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(message['timestamp'] as DateTime, locale: 'es'),
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        if ((message['reactions'] as Map<String, int>).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: (message['reactions'] as Map<String, int>).entries.map((entry) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${entry.value}',
                                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isMe)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.deepOrangeAccent,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _isTyping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Global'),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        elevation: 2,
        shadowColor: Colors.black45,
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white70),
            onPressed: _toggleMute,
            tooltip: _isMuted ? 'Activar notificaciones' : 'Silenciar notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unirse a sesión: Próximamente')),
              );
            },
            tooltip: 'Unirse a una sesión',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70),
            onPressed: _clearChat,
            tooltip: 'Limpiar chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              initialItemCount: _messages.length + (_messageController.text.trim().isNotEmpty ? 1 : 0),
              itemBuilder: (context, index, animation) {
                if (index == _messages.length && _messageController.text.trim().isNotEmpty) {
                  // Mensaje de previsualización
                  return FadeTransition(
                    opacity: animation,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepOrangeAccent.withOpacity(0.3),
                              Colors.deepOrangeAccent.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_userNickname ${_getCountryFlag(_userCountry)}',
                                    style: TextStyle(
                                      color: Colors.deepOrangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _messageController.text.trim(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Previsualización',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.deepOrangeAccent,
                              child: Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final message = _messages[index];
                final isMe = message['user'] == _userNickname;
                return _buildMessageWidget(message, animation, isMe);
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isTyping,
            builder: (context, isTyping, child) {
              return isTyping
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Escribiendo...', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                ),
              )
                  : const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Respondiendo a ${_replyingTo!['user']}: ${_replyingTo!['message']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => setState(() => _replyingTo = null),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white54),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) {
                          _isTyping.value = text.trim().isNotEmpty;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepOrangeAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}