/// Represents a comment on a YouTube video with interactive like state
class CommentModel {
  final String id;
  final String author;
  final String authorAvatar;
  final String text;
  final String publishedTime;
  final int likeCount;
  final bool isLikedByMe;

  const CommentModel({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.text,
    required this.publishedTime,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  String get likeCountFormatted {
    if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    }
    if (likeCount > 0) {
      return '$likeCount';
    }
    return '';
  }

  CommentModel copyWith({
    String? id,
    String? author,
    String? authorAvatar,
    String? text,
    String? publishedTime,
    int? likeCount,
    bool? isLikedByMe,
  }) {
    return CommentModel(
      id: id ?? this.id,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      publishedTime: publishedTime ?? this.publishedTime,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'authorAvatar': authorAvatar,
      'text': text,
      'publishedTime': publishedTime,
      'likeCount': likeCount,
      'isLikedByMe': isLikedByMe,
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? 'User',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      text: json['text'] as String? ?? '',
      publishedTime: json['publishedTime'] as String? ?? 'Just now',
      likeCount: json['likeCount'] as int? ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
    );
  }
}
