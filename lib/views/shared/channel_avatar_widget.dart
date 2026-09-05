import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/youtube_service.dart';

/// Authentic YouTube Dynamic Channel Avatar Widget.
/// Displays genuine YouTube channel avatar images dynamically.
/// Resolves avatars dynamically via YouTube API, known channel registry, and runtime cache.
class ChannelAvatarWidget extends StatefulWidget {
  final String author;
  final String avatarUrl;
  final String channelId;
  final double radius;

  const ChannelAvatarWidget({
    super.key,
    required this.author,
    required this.avatarUrl,
    this.channelId = '',
    this.radius = 18,
  });

  @override
  State<ChannelAvatarWidget> createState() => _ChannelAvatarWidgetState();
}

class _ChannelAvatarWidgetState extends State<ChannelAvatarWidget> {
  String _effectiveAvatarUrl = '';
  bool _isFetchingDynamic = false;

  static const Map<String, String> _knownChannelAvatars = {
    'somoy tv': 'https://yt3.ggpht.com/HIVp56M09fDcVPKGpRXkl47xJcG7JGV5Mwn8E_7TlwmPgjgg1MQ7t_oxiy4xkmgo5fmWxilY3yU=s176-c-k-c0x00ffffff-no-rj',
    'somoy news': 'https://yt3.ggpht.com/HIVp56M09fDcVPKGpRXkl47xJcG7JGV5Mwn8E_7TlwmPgjgg1MQ7t_oxiy4xkmgo5fmWxilY3yU=s176-c-k-c0x00ffffff-no-rj',
    'jamuna tv': 'https://yt3.ggpht.com/54prTx28YpPxSpk_PfJGuOfQgcZbNdvbfk0adGePrAvINO4Mo9_bw3j-J4seXn6hNGuMr1ck=s176-c-k-c0x00ffffff-no-rj-mo',
    'jamuna television': 'https://yt3.ggpht.com/54prTx28YpPxSpk_PfJGuOfQgcZbNdvbfk0adGePrAvINO4Mo9_bw3j-J4seXn6hNGuMr1ck=s176-c-k-c0x00ffffff-no-rj-mo',
    'channel 24': 'https://yt3.ggpht.com/8Q8MCd6ypr2Hzbp60VE_stJPl063kQYfeTxdIQkAXRfhdzxByLl0sJYHsk43uTM4W_cOzwcbPQ=s176-c-k-c0x00ffffff-no-rj-mo',
    'bbc news': 'https://yt3.ggpht.com/v4JamQ9B-PUiJHjmZQs9UwTaoLQW8vijJMMpV5QvA2wHQ6iwWM8Q1s6O4jgTl0dtDigVWAi7SA=s176-c-k-c0x00ffffff-no-rj-mo',
    'al jazeera english': 'https://yt3.ggpht.com/XsTga3Nsfc1E6ZgC6HfHfzTG_3zhuZleOnsKxSK2aILMjwkkIm-0vdALFaU-yt0Lw07iLtbSifk=s176-c-k-c0x00ffffff-no-rj-mo',
    'al jazeera': 'https://yt3.ggpht.com/XsTga3Nsfc1E6ZgC6HfHfzTG_3zhuZleOnsKxSK2aILMjwkkIm-0vdALFaU-yt0Lw07iLtbSifk=s176-c-k-c0x00ffffff-no-rj-mo',
    'al jazeera arabic': 'https://yt3.ggpht.com/oN_i26ADOuQ4PdypHo8yjVXh6QSXZ1kMeYzaRH3hNOlQE1uEUUQ-gkCh0o1rUQ2PM7Qx6QvY2g=s176-c-k-c0x00ffffff-no-rj-mo',
    'independent television': 'https://yt3.ggpht.com/JO8MicN497ze8WVXcu-wmA2WAMqhO8UIQhslV3VhiRu1kaQU3r9nOB4IVkmUt0ALC23DVSSp=s176-c-k-c0x00ffffff-no-rj',
    'independent tv': 'https://yt3.ggpht.com/JO8MicN497ze8WVXcu-wmA2WAMqhO8UIQhslV3VhiRu1kaQU3r9nOB4IVkmUt0ALC23DVSSp=s176-c-k-c0x00ffffff-no-rj',
    'news24': 'https://yt3.ggpht.com/FK8kaDWHXG4F4yCVGbGP9gE5hNOOTBTXof6KFMrhj3BZ2yW0oHy7PxJRRP8QdMZfGWCNTG3L4g=s176-c-k-c0x00ffffff-no-rj-mo',
    'ntv news': 'https://yt3.ggpht.com/n0w_a7cVrXgq83ypq7_Bz-VWic65siyBUUlbTz5iM9awakndtez7nDapCyZNiBI3HLd_w8dfCZ0=s176-c-k-c0x00ffffff-no-rj',
    'rtv news': 'https://yt3.ggpht.com/Jw5N_GsIqsDis5cvYkAlJZFU2Z3m_6q6GaTdmUK0hJ4bsadl4He51sFu1LoCGKmf3QiTG-9P5G4=s176-c-k-c0x00ffffff-no-rj-mo',
    'ekattor tv': 'https://yt3.ggpht.com/M8Rqad6_uN86mMSvd9KGkE5G2mrVAgvfTV-VCsQb6jhfF5hEbcQCEJiInih4wb2fMQ_RG7Ku=s176-c-k-c0x00ffffff-no-rj-mo',
    'veritasium': 'https://yt3.ggpht.com/7vCbvtCqtjQ3YLgsJt7Y952MQV1sBvhllSCSxHP8_sVZdcPCBrITfhkN2RdyCuwPnsByq-1GoA=s176-c-k-c0x00ffffff-no-rj-mo',
    'ted-ed': 'https://yt3.ggpht.com/PKUi-Lc3VFjUfsIhjK3n-FJDNBf-XQLdg4G4bv4fPFF96D3MVnkbub9ePpLoWdmdFgl5I1Zd=s176-c-k-c0x00ffffff-no-rj-mo',
    'nasa': 'https://yt3.ggpht.com/eIf5fNPcIcj9ig-wZBeq4stFy1lgjWTW1nLT5dYlFkHZprZ03QBiMcbpwNMB6XSBjrSFGtAGQg=s176-c-k-c0x00ffffff-no-rj-mo',
    'as-sunnah foundation': 'https://yt3.ggpht.com/ytc/AIdro_kmsjs7L9AOWOUX-vhwVh3Ody05f6C9rrjcSTkAFsbDGg=s176-c-k-c0x00ffffff-no-rj',
    'dw news': 'https://yt3.ggpht.com/NSOdTQTWlqMy8O_j32dx-ftfTCHMOt04Hm7KZ4pfAK6-eQzQSZMWvvss90kG8KQfJ7iNP3phyA=s176-c-k-c0x00ffffff-no-rj-mo',
    'cnn': 'https://yt3.ggpht.com/wSqAf5WdxsGsl7ZMtlyfz3qKULo_URoFjmKky0gLThm_Jtu2wsVHMu-XzGZPAb-z8zeMBYUUMYA=s176-c-k-c0x00ffffff-no-rj-mo',
    'mrbeast': 'https://yt3.ggpht.com/nxYrc_1_2f77DoBadyxMTmv7ZpRZapHR5jbuYe7PlPd5cIRJxtNNEYyOC0ZsxaDyJJzXrnJiuDE=s176-c-k-c0x00ffffff-no-rj-mo',
  };

  @override
  void initState() {
    super.initState();
    _resolveAvatar();
  }

  @override
  void didUpdateWidget(covariant ChannelAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl ||
        oldWidget.author != widget.author ||
        oldWidget.channelId != widget.channelId) {
      _resolveAvatar();
    }
  }

  void _resolveAvatar() {
    final normAuthor = widget.author.toLowerCase().trim();

    // 1. Check known verified channel avatar registry first
    if (_knownChannelAvatars.containsKey(normAuthor)) {
      _effectiveAvatarUrl = _knownChannelAvatars[normAuthor]!;
      return;
    }
    for (final entry in _knownChannelAvatars.entries) {
      if (normAuthor.contains(entry.key) || entry.key.contains(normAuthor)) {
        _effectiveAvatarUrl = entry.value;
        return;
      }
    }

    // 2. If given URL is valid and not a placeholder hash
    if (_isValidUrl(widget.avatarUrl)) {
      _effectiveAvatarUrl = widget.avatarUrl;
      return;
    }

    // 3. Check runtime dynamic cache from prior YouTube responses
    final cached = YoutubeService.getCachedChannelAvatar(
      widget.author,
      channelId: widget.channelId,
    );
    if (cached.isNotEmpty && _isValidUrl(cached)) {
      _effectiveAvatarUrl = cached;
      return;
    }

    // 4. Dynamically fetch from YouTube API at runtime
    _fetchAvatarDynamically();
  }

  void _fetchAvatarDynamically() {
    if (_isFetchingDynamic) return;
    if (widget.author.isEmpty && widget.channelId.isEmpty) return;

    _isFetchingDynamic = true;
    YoutubeService.instance
        .fetchChannelAvatarDynamic(widget.author, channelId: widget.channelId)
        .then((url) {
      if (mounted) {
        _isFetchingDynamic = false;
        if (url.isNotEmpty && _isValidUrl(url)) {
          setState(() {
            _effectiveAvatarUrl = url;
          });
        }
      }
    }).catchError((_) {
      if (mounted) _isFetchingDynamic = false;
    });
  }

  bool _isValidUrl(String url) {
    return url.isNotEmpty &&
        !url.contains('unsplash.com') &&
        !url.contains('AIdro_k2Lg0Yq3qOQ') &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveAvatarUrl.isNotEmpty) {
      return Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: kIsWeb
            ? Image.network(
                _effectiveAvatarUrl,
                width: widget.radius * 2,
                height: widget.radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchAvatarDynamically();
                  });
                  return _buildChannelIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildChannelIcon();
                },
              )
            : CachedNetworkImage(
                imageUrl: _effectiveAvatarUrl,
                width: widget.radius * 2,
                height: widget.radius * 2,
                fit: BoxFit.cover,
                errorListener: (_) {},
                placeholder: (context, url) => _buildChannelIcon(),
                errorWidget: (context, url, error) {
                  // Trigger dynamic fetch on network failure
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchAvatarDynamically();
                  });
                  return _buildChannelIcon();
                },
              ),
      );
    }

    return _buildChannelIcon();
  }

  /// Authentic YouTube-style channel emblem/icon when image is loading or offline
  Widget _buildChannelIcon() {
    final clean = widget.author.trim().toLowerCase();

    IconData channelIcon = Icons.smart_display_rounded;
    Color iconBg = const Color(0xFF282828);
    Color iconColor = const Color(0xFF3EA6FF);

    if (clean.contains('news') || clean.contains('tv') || clean.contains('24') || clean.contains('bbc')) {
      channelIcon = Icons.live_tv_rounded;
      iconColor = const Color(0xFFFF4E45);
    } else if (clean.contains('tech') || clean.contains('code') || clean.contains('ai') || clean.contains('veritasium')) {
      channelIcon = Icons.memory_rounded;
      iconColor = const Color(0xFF2BA640);
    } else if (clean.contains('islam') || clean.contains('sunnah') || clean.contains('quran') || clean.contains('waz')) {
      channelIcon = Icons.mosque_rounded;
      iconColor = const Color(0xFF00BFA5);
    } else if (clean.contains('music') || clean.contains('song') || clean.contains('audio')) {
      channelIcon = Icons.music_note_rounded;
      iconColor = const Color(0xFFFF7700);
    } else if (clean.contains('science') || clean.contains('nasa') || clean.contains('space') || clean.contains('ted')) {
      channelIcon = Icons.rocket_launch_rounded;
      iconColor = const Color(0xFF9C27B0);
    }

    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Center(
        child: Icon(
          channelIcon,
          size: widget.radius * 1.1,
          color: iconColor,
        ),
      ),
    );
  }
}
