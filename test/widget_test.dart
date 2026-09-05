import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_tune/core/constants/app_categories.dart';
import 'package:tube_tune/core/services/auth_service.dart';
import 'package:tube_tune/core/services/filter_service.dart';
import 'package:tube_tune/core/services/storage_service.dart';
import 'package:tube_tune/models/video_model.dart';
import 'package:tube_tune/viewmodels/auth_viewmodel.dart';
import 'package:tube_tune/views/shared/cast_bottom_sheet.dart';
import 'package:tube_tune/views/shared/google_signin_dialog.dart';

void main() {
  test('FilterService blocks 18+ content and out-of-category content', () {
    final filterService = FilterService.instance;

    const adultVideo = VideoModel(
      id: 'v1',
      title: '18+ Hot Explicit Romance',
      author: 'Sensual Vibes',
      channelId: 'ch1',
      thumbnailUrl: '',
      duration: Duration(minutes: 5),
      viewCount: 100,
      uploadDate: 'Today',
      isAgeRestricted: false,
    );

    const wazVideo = VideoModel(
      id: 'v2',
      title: 'Dr Zakir Naik on Purpose of Life Waz Lecture',
      author: 'Islamic Peace',
      channelId: 'ch2',
      thumbnailUrl: '',
      duration: Duration(minutes: 30),
      viewCount: 5000,
      uploadDate: 'Yesterday',
      categoryTag: AppCategories.categoryIslamicWaz,
    );

    // 1. Check 18+ blocker
    expect(filterService.is18Plus(adultVideo), isTrue);
    expect(filterService.is18Plus(wazVideo), isFalse);

    // 2. Check category isolation: when Islamic category is selected, waz video is allowed
    final allowed = filterService.isAllowedVideo(
      wazVideo,
      enableShorts: true,
      block18Plus: true,
      strictCategoryMode: true,
      enabledCategories: [AppCategories.defaultCategories.firstWhere((c) => c.id == AppCategories.categoryIslamicWaz)],
      customBlacklist: [],
    );
    expect(allowed, isTrue);
  });

  testWidgets('CastBottomSheet renders cleanly without ListTile DecoratedBox assertion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CastBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect to a device'), findsOneWidget);
    expect(find.text('Link with TV code'), findsOneWidget);
  });

  testWidgets('GoogleSignInDialog renders cleanly without assertion errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();
    final authService = await AuthService.getInstance(storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(authService: authService),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoogleSignInDialog(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}

