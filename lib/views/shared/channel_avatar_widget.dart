import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Authentic YouTube Channel Avatar Widget.
/// Renders authentic YouTube live avatars or official broadcast channel badges.
/// Rejects stock/fake/dummy placeholder photos.
class ChannelAvatarWidget extends StatelessWidget {
  final String author;
  final String avatarUrl;
  final double radius;

  const ChannelAvatarWidget({
    super.key,
    required this.author,
    required this.avatarUrl,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isValidUrl = avatarUrl.isNotEmpty &&
        !avatarUrl.contains('unsplash.com') &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    if (isValidUrl) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildBrandBadge(),
          errorWidget: (context, url, error) => _buildBrandBadge(),
        ),
      );
    }

    return _buildBrandBadge();
  }

  Widget _buildBrandBadge() {
    final lower = author.toLowerCase().trim();
    Color bg = AppColors.surfaceElevated;
    String label = author.isNotEmpty ? author[0].toUpperCase() : 'Y';
    Color textColor = Colors.white;

    if (lower.contains('bbc')) {
      bg = const Color(0xFFBB1919);
      label = 'BBC';
    } else if (lower.contains('somoy')) {
      bg = const Color(0xFFD32F2F);
      label = 'সময়';
    } else if (lower.contains('jamuna')) {
      bg = const Color(0xFFFFB300);
      textColor = Colors.black;
      label = 'JTV';
    } else if (lower.contains('cnn')) {
      bg = const Color(0xFFCC0000);
      label = 'CNN';
    } else if (lower.contains('al jazeera')) {
      bg = const Color(0xFFE5A823);
      textColor = Colors.black;
      label = 'AJ';
    } else if (lower.contains('channel 24')) {
      bg = const Color(0xFF1976D2);
      label = '24';
    } else if (lower.contains('rtv')) {
      bg = const Color(0xFF2E7D32);
      label = 'RTV';
    } else if (lower.contains('dw')) {
      bg = const Color(0xFF003366);
      label = 'DW';
    } else if (lower.contains('mrbeast')) {
      bg = const Color(0xFF00B0FF);
      label = 'MB';
    } else if (lower.contains('veritasium')) {
      bg = const Color(0xFF00796B);
      label = 'V';
    } else if (lower.contains('mkbhd')) {
      bg = const Color(0xFF212121);
      textColor = const Color(0xFFFF5252);
      label = 'M';
    } else if (lower.contains('nasa')) {
      bg = const Color(0xFF0B3D91);
      label = 'NASA';
    } else if (lower.contains('nat geo') || lower.contains('national geographic')) {
      bg = const Color(0xFFFFCC00);
      textColor = Colors.black;
      label = 'NG';
    } else if (lower.contains('ted')) {
      bg = const Color(0xFFE62B1E);
      label = 'TED';
    } else {
      final palette = [
        const Color(0xFFE91E63),
        const Color(0xFF9C27B0),
        const Color(0xFF673AB7),
        const Color(0xFF3F51B5),
        const Color(0xFF2196F3),
        const Color(0xFF009688),
        const Color(0xFF4CAF50),
        const Color(0xFFFF9800),
      ];
      bg = palette[author.hashCode.abs() % palette.length];
    }

    final fontSize = label.length > 3
        ? radius * 0.50
        : (label.length > 1 ? radius * 0.65 : radius * 0.85);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
