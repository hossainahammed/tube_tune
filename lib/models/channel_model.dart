/// Channel Model representing a YouTube channel with subscription status and dynamic metadata
class ChannelModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String subscriberCount;
  final bool isVerified;
  final String description;
  final bool isSubscribed;
  final bool hasNewUpload;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.subscriberCount,
    this.isVerified = false,
    this.description = '',
    this.isSubscribed = false,
    this.hasNewUpload = false,
  });

  ChannelModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? subscriberCount,
    bool? isVerified,
    String? description,
    bool? isSubscribed,
    bool? hasNewUpload,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      hasNewUpload: hasNewUpload ?? this.hasNewUpload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'subscriberCount': subscriberCount,
      'isVerified': isVerified,
      'description': description,
      'isSubscribed': isSubscribed,
      'hasNewUpload': hasNewUpload,
    };
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      subscriberCount: json['subscriberCount'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      hasNewUpload: json['hasNewUpload'] as bool? ?? false,
    );
  }
}
