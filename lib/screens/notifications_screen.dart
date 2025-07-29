import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, String>> notifications;
  final VoidCallback onClear;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: notifications.isNotEmpty
                ? () {
              onClear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones eliminadas')),
              );
            }
                : null,
            tooltip: 'Limpiar notificaciones',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          'No hay notificaciones.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            leading: const Icon(Icons.notifications, color: Colors.deepOrangeAccent),
            title: Text(
              notification['message']!,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notificación: ${notification['message']}')),
              );
            },
          );
        },
      ),
    );
  }
}