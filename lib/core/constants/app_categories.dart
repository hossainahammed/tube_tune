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

  static final List<CategoryModel> defaultCategories = [
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
      id: categoryNews,
      name: 'BD TV & News',
      icon: Icons.live_tv_rounded,
      color: AppColors.newsBlue,
      description: 'All Bangladesh TV Channels (Somoy, Jamuna, Channel 24, Ekattor, DBC, NTV, RTV, Channel i, BTV, News24), BBC Bangla & Global News',
      keywords: [
        'news', 'bulletin', 'current affairs', 'breaking news', 'report',
        // Bangladesh TV Channels & Media (English & Bengali)
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
        // Bangladeshi Newspapers & Online Portals
        'prothom alo', 'প্রথম আলো',
        'the daily star', 'daily star', 'ডেইলি স্টার',
        'bdnews24', 'বিডিনিউজ২৪',
        'jago news', 'jagonews24', 'bangla tribune', 'dhaka post',
        'jugantor', 'kaler kantho', 'ittefaq', 'manab zamin',
        // Bengali International Broadcasts
        'bbc bangla', 'bbc news bangla', 'বিবিসি বাংলা',
        'dw bangla', 'ডয়চে ভেলে বাংলা',
        'voa bangla', 'ভয়েস অব আমেরিকা বাংলা',
        // General News & International Outlets
        'bangla news', 'bangla khobor', 'taza khobor', 'shongbad',
        'bangladesh news', 'bangladesh live tv', 'bd tv', 'bd news', 'live tv',
        'al jazeera', 'bbc news', 'bbc world', 'reuters', 'dw news', 'cnn',
        'france 24', 'sky news', 'geopolitics', 'world news', 'global news',
        'headlines', 'documentary', 'press conference', 'analysis', 'talk show'
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
