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
      name: 'News & Updates',
      icon: Icons.newspaper_rounded,
      color: AppColors.newsBlue,
      description: 'Somoy TV, Jamuna TV, BBC News, BBC Bangla, Al Jazeera, Reuters, World News',
      keywords: [
        'news', 'bulletin', 'current affairs', 'breaking news', 'report',
        'somoy tv', 'somoy news', 'jamuna tv', 'jamuna news', 'channel 24',
        'independent tv', 'ekattor tv', 'dbc news', 'prothom alo', 'bbc bangla',
        'bangla news', 'bangladesh news', 'shongbad', 'khobor', 'al jazeera',
        'bbc news', 'bbc world', 'reuters', 'dw news', 'cnn', 'france 24',
        'sky news', 'geopolitics', 'world news', 'global news', 'headlines',
        'documentary', 'press conference', 'analysis', 'talk show'
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
