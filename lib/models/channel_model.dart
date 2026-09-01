/// Channel Model representing a YouTube channel
class ChannelModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String subscriberCount;
  final bool isVerified;
  final String description;
  final bool isSubscribed;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.subscriberCount,
    this.isVerified = false,
    this.description = '',
    this.isSubscribed = false,
  });

  ChannelModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? subscriberCount,
    bool? isVerified,
    String? description,
    bool? isSubscribed,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}
