class ForumPost {
  final String id;
  final String user;
  final int level;
  final String country;
  final String title;
  final String content;
  final DateTime timestamp;
  final List<ForumComment> comments;
  final Map<String, int> reactions;

  ForumPost({
    required this.id,
    required this.user,
    required this.level,
    required this.country,
    required this.title,
    required this.content,
    required this.timestamp,
    List<ForumComment>? comments,
    Map<String, int>? reactions,
  })  : comments = comments ?? [],
        reactions = reactions ?? {};
}

class ForumComment {
  final String id;
  final String user;
  final int level;
  final String country;
  final String content;
  final DateTime timestamp;
  final String? parentCommentId;

  ForumComment({
    required this.id,
    required this.user,
    required this.level,
    required this.country,
    required this.content,
    required this.timestamp,
    this.parentCommentId,
  });
}