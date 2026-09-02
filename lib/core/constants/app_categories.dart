import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/category_model.dart';

class AppCategories {
  AppCategories._();

  static const String categoryAll = 'all';
  static const String categoryIslamicWaz = 'islamic_waz';
  static const String categoryKidsCartoons = 'kids_cartoons';
  static const String categoryNews = 'news';
  static const String categoryEducationTech = 'education_tech';
  static const String categoryHalalNasheed = 'halal_nasheed';
  static const String categoryCooking = 'cooking';
  static const String categorySports = 'sports';
  static const String categoryMusicSongs = 'music_songs';
  static const String categoryMoviesCinema = 'movies_cinema';
  static const String categoryEntertainment = 'entertainment';
  static const String categoryLiveTv = 'live_tv';

  static final List<CategoryModel> defaultCategories = [
    const CategoryModel(
      id: categoryNews,
      name: 'News',
      icon: Icons.newspaper_rounded,
      color: AppColors.newsBlue,
      description: 'All National & International News (Somoy, Jamuna, BBC, CNN, Al Jazeera, Reuters, DW, Channel 24, Ekattor, BTV, AP & World News)',
      keywords: [
        // Core News Terms
        'news', 'bulletin', 'current affairs', 'breaking news', 'report',
        'headlines', 'documentary', 'press conference', 'analysis', 'talk show',
        'journalism', 'daily news', 'live news', 'today news', 'world news',
        'international news', 'global news', 'national news', 'geopolitics',
        'politics', 'parliament', 'election', 'diplomacy', 'economy', 'finance',
        'investigation', 'special report', 'broadcast', 'morning news', 'evening news',
        'nightly news', 'news hour', 'prime time', 'press briefing', 'united nations',

        // Global & International Media (World News Networks)
        'bbc', 'bbc news', 'bbc world', 'bbc world news', 'bbc bangla', 'বিবিসি বাংলা',
        'cnn', 'cnn news', 'cnn international',
        'al jazeera', 'al jazeera english', 'al jazeera news', 'aljazeera',
        'reuters', 'reuters news', 'reuters official',
        'associated press', 'ap news', 'ap',
        'dw', 'dw news', 'dw documentary', 'dw bangla', 'ডয়চে ভেলে বাংলা',
        'france 24', 'france24', 'france 24 english',
        'sky news', 'sky news live',
        'bloomberg', 'bloomberg news', 'bloomberg technology',
        'cnbc', 'cnbc international',
        'voa', 'voa news', 'voa bangla', 'ভয়েস অব আমেরিকা বাংলা',
        'wion', 'wion news',
        'trt world', 'trt',
        'euronews', 'euronews english',
        'nbc news', 'abc news', 'cbs news', 'fox news', 'pbs newshour',
        'nhk world', 'cna', 'channel newsasia',

        // Bangladeshi National TV & Media (English & Bengali)
        'somoy tv', 'somoy news', 'সময় টিভি', 'সময় সংবাদ',
        'jamuna tv', 'jamuna news', 'যমুনা টিভি', 'যমুনা নিউজ',
        'channel 24', 'চ্যানেল ২৪', 'চ্যানেল 24',
        'independent tv', 'independent television', 'ইন্ডিপেন্ডেন্ট টিভি',
        'ekattor tv', 'ekattor news', 'একাত্তর টিভি', '71 tv',
        'dbc news', 'ডিবিসি নিউজ',
        'news24', 'news 24', 'নিউজ ২৪', 'নিউজ 24',
        'atn news', 'এটিএন নিউজ', 'atn bangla', 'এটিএন বাংলা',
        'channel i', 'চ্যানেল আই', 'channel i news',
        'ntv', 'ntv news', 'ntv bangla', 'এনটিভি',
        'rtv', 'rtv news', 'rtv plus', 'আরটিভি',
        'banglavision', 'banglavision news', 'বাংলাভিশন',
        'boishakhi tv', 'বৈশাখী টিভি',
        'maasranga tv', 'maasranga television', 'মাছরাঙা টিভি',
        'gazi tv', 'gtv', 'জিটিভি',
        'btv', 'btv news', 'btv world', 'বাংলাদেশ টেলিভিশন', 'বিটিভি',
        'desh tv', 'দেশ টিভি',
        'deepto tv', 'দীপ্ত টিভি',
        'nagorik tv', 'নাগরিক টিভি',
        't sports', 'টি স্পোর্টস',
        'asian tv', 'bijoy tv', 'ananda tv', 'global tv', 'nexus tv',
        'prothom alo', 'প্রথম আলো',
        'the daily star', 'daily star', 'ডেইলি স্টার',
        'bdnews24', 'বিডিনিউজ২৪',
        'jago news', 'jagonews24', 'bangla tribune', 'dhaka post',
        'jugantor', 'kaler kantho', 'ittefaq', 'manab zamin',
        'bangla news', 'bangla khobor', 'taza khobor', 'shongbad',
        'bangladesh news', 'bangladesh live tv', 'bd tv', 'bd news', 'live tv'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categoryIslamicWaz,
      name: 'Islamic & Waz',
      icon: Icons.mosque_rounded,
      color: AppColors.islamicGreen,
      description: 'Quran recitation, Waz lectures, Tafseer, Islamic scholars & reminders',
      keywords: [
        'waz', 'islamic', 'quran', 'tafseer', 'lecture', 'scholar',
        'mizanur rahman azhari', 'ahmadullah', 'delwar hossain sayeedi',
        'abu toha', 'mufti menk', 'dr zakir naik', 'omar suleiman',
        'nouman ali khan', 'surah', 'tilawat', 'bayan', 'khutbah',
        'hadith', 'prophet', 'dua', 'namaz', 'ramadan', 'seerah',
        'islamic lecture', 'bangla waz', 'urdu bayan', 'sunnah'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categoryKidsCartoons,
      name: 'Kids & Cartoons',
      icon: Icons.child_care_rounded,
      color: AppColors.kidsOrange,
      description: 'Kid-safe cartoons, moral animations, nursery rhymes & educational stories',
      keywords: [
        'cartoon', 'cartoons', 'animation', 'kids', 'toddler', 'nursery rhymes',
        'meena cartoon', 'tom and jerry', 'pinkfong', 'cocomelon', 'moral story',
        'fairy tale', 'animated story', 'kids learning', 'alphabet', 'animals for kids',
        'chuchu tv', 'motu patlu', 'peppa pig', 'ben 10', 'kid songs', 'bedtime story'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categoryEducationTech,
      name: 'Education & Tech',
      icon: Icons.school_rounded,
      color: AppColors.techIndigo,
      description: 'Programming, tech tutorials, science documentaries, math & learning',
      keywords: [
        'mrbeast', 'mkbhd', 'marques brownlee', 'veritasium', 'mark rober',
        'national geographic', 'nat geo', 'nasa', 'ted', 'ted-ed', 'kurzgesagt',
        'fireship', 'freecodecamp', 'discovery', 'planet earth', 'history',
        'experiment', 'challenge', 'innovation', 'astronomy',
        'flutter', 'python', 'programming', 'coding', 'technology',
        'computer science', 'tutorial', 'course', 'science', 'physics',
        'mathematics', 'khan academy', 'crash course', 'artificial intelligence',
        'machine learning', 'web development', 'gadgets', 'tech review',
        'documentary', 'space', 'engineering', 'study'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categoryHalalNasheed,
      name: 'Nasheed & Audio',
      icon: Icons.library_music_rounded,
      color: AppColors.accentCyan,
      description: 'Soulful vocals-only nasheeds, peaceful ambient & Quran audio',
      keywords: [
        'nasheed', 'islamic song', 'vocal only', 'acapella nasheed',
        'maher zain', 'sami yusuf', 'hamza namira', 'peaceful nasheed',
        'quran recitation', 'lofi halal', 'subhanallah', 'heart touching nasheed',
        'arabic nasheed', 'english nasheed', 'bangla nasheed'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categoryCooking,
      name: 'Cooking & Food',
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.accentAmber,
      description: 'Cooking tutorials, culinary recipes & kitchen tips',
      keywords: [
        'recipe', 'cooking', 'chef', 'food', 'kitchen', 'baking',
        'delicious', 'street food', 'how to cook', 'dinner recipe',
        'breakfast', 'village cooking', 'healthy food'
      ],
      isEnabled: true,
    ),
    const CategoryModel(
      id: categorySports,
      name: 'Sports & Fitness',
      icon: Icons.sports_soccer_rounded,
      color: AppColors.accentGreen,
      description: 'Cricket, football highlights, workout routines & fitness training',
      keywords: [
        'cricket', 'football', 'soccer', 'sports', 'match highlights',
        'workout', 'fitness', 'gym', 'calisthenics', 'world cup',
        'messi', 'ronaldo', 'premier league', 'icc', 'highlights'
      ],
      isEnabled: true,
    ),
  ];

  static const CategoryModel musicCategory = CategoryModel(
    id: categoryMusicSongs,
    name: 'Music & Songs',
    icon: Icons.music_note_rounded,
    color: Color(0xFFE91E63),
    description: 'Official music videos, hit songs, pop tracks, concerts & audio',
    keywords: [
      'song', 'songs', 'music', 'official music video', 'audio song', 'lyrics',
      'bangla song', 'hindi song', 'bollywood song', 'english song', 'pop song',
      'hit song', 'album', 'singer', 'soundtrack', 'remix song', 'concert'
    ],
    isEnabled: true,
  );

  static const CategoryModel moviesCategory = CategoryModel(
    id: categoryMoviesCinema,
    name: 'Movies & Cinema',
    icon: Icons.movie_creation_rounded,
    color: Color(0xFFFF5722),
    description: 'Full movies, trailers, cinema releases, action films & entertainment',
    keywords: [
      'movie', 'movies', 'film', 'cinema', 'full movie', 'trailer', 'official trailer',
      'teaser', 'action movie', 'bangla movie', 'hollywood movie', 'bollywood movie',
      'blockbuster', 'drama film', 'short film', 'cinema release', 'box office'
    ],
    isEnabled: true,
  );

  static const CategoryModel liveTvCategory = CategoryModel(
    id: categoryLiveTv,
    name: 'Live TV',
    icon: Icons.sensors_rounded,
    color: AppColors.youtubeRed,
    description: '24/7 Live television channels from Bangladesh and international broadcasters',
    keywords: [
      'live', 'live tv', 'live stream', '24/7', 'broadcasting', 'sarasori', 'সরাসরি',
      'somoy live', 'jamuna live', 'bbc live', 'al jazeera live', 'rtv live',
      'channel 24 live', 'cnn live', 'sky news live', 'watch live'
    ],
    isEnabled: true,
  );

  static List<CategoryModel> get allAvailableCategories => [
    ...defaultCategories,
    liveTvCategory,
    musicCategory,
    moviesCategory,
  ];

  /// Comprehensive list of adult, 18+, NSFW, vulgar, and inappropriate terms to block
  static const List<String> blocked18PlusKeywords = [
    '18+', 'nsfw', 'adult', 'sex', 'sexy', 'porn', 'xxx', 'erotic', 'nude',
    'nudity', 'bikini', 'hot girl', 'sensual', 'boobs', 'cleavage', 'kissing scene',
    'bedroom scene', 'romance hot', 'bold scene', 'explicit', 'uncensored',
    'web series hot', 'ullu', 'kangan', 'hot dance', 'dirty talk', 'desire',
    'lust', 'strip', 'lingerie', 'violence', 'blood', 'gore', 'slaughter',
    'killing', 'abuse', 'drug', 'gambling', 'casino', 'betting', 'scam'
  ];
}
