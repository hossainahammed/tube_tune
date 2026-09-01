/// Represents a comment on a YouTube video
class CommentModel {
  final String id;
  final String author;
  final String authorAvatar;
  final String text;
  final String publishedTime;
  final int likeCount;

  const CommentModel({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.text,
    required this.publishedTime,
    this.likeCount = 0,
  });

  String get likeCountFormatted {
    if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    }
    return '$likeCount';
  }
}
