/// Model representing a Google / YouTube signed-in user account
class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String channelName;
  final int subscribersCount;
  final bool isLoggedIn;

  const UserModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.avatarUrl = '',
    this.channelName = '',
    this.subscribersCount = 0,
    this.isLoggedIn = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? channelName,
    int? subscribersCount,
    bool? isLoggedIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      channelName: channelName ?? this.channelName,
      subscribersCount: subscribersCount ?? this.subscribersCount,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'channelName': channelName,
      'subscribersCount': subscribersCount,
      'isLoggedIn': isLoggedIn,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      subscribersCount: json['subscribersCount'] as int? ?? 0,
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
    );
  }
}
