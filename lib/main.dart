import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/timer_service.dart';
import 'core/services/youtube_service.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/player_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'viewmodels/shorts_viewmodel.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio foreground service for continuous playback
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.tube_tune.channel.audio',
      androidNotificationChannelName: 'TubeTune Background Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  } catch (_) {}

  // Set system navigation bar & status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Core Services
  final storageService = await StorageService.getInstance();
  final timerService = await TimerService.getInstance(storageService);
  final authService = await AuthService.getInstance(storageService);
  final youtubeService = YoutubeService.instance;

  runApp(
    TubeTuneApp(
      storageService: storageService,
      timerService: timerService,
      authService: authService,
      youtubeService: youtubeService,
    ),
  );
}

class TubeTuneApp extends StatelessWidget {
  final StorageService storageService;
  final TimerService timerService;
  final AuthService authService;
  final YoutubeService youtubeService;

  const TubeTuneApp({
    super.key,
    required this.storageService,
    required this.timerService,
    required this.authService,
    required this.youtubeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timerService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            storage: storageService,
            timerService: timerService,
          ),
        ),
        ChangeNotifierProxyProvider<SettingsViewModel, HomeViewModel>(
          create: (ctx) => HomeViewModel(
            youtubeService: youtubeService,
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
          update: (ctx, settingsVm, homeVm) =>
              homeVm ??
              HomeViewModel(
                youtubeService: youtubeService,
                settingsViewModel: settingsVm,
              ),
        ),
        ChangeNotifierProxyProvider<SettingsViewModel, SearchViewModel>(
          create: (ctx) => SearchViewModel(
            youtubeService: youtubeService,
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
          update: (ctx, settingsVm, searchVm) =>
              searchVm ??
              SearchViewModel(
                youtubeService: youtubeService,
                settingsViewModel: settingsVm,
              ),
        ),
        ChangeNotifierProxyProvider<SettingsViewModel, ShortsViewModel>(
          create: (ctx) => ShortsViewModel(
            youtubeService: youtubeService,
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
          update: (ctx, settingsVm, shortsVm) =>
              shortsVm ??
              ShortsViewModel(
                youtubeService: youtubeService,
                settingsViewModel: settingsVm,
              ),
        ),
        ChangeNotifierProxyProvider<SettingsViewModel, PlayerViewModel>(
          create: (ctx) => PlayerViewModel(
            storage: storageService,
            youtubeService: youtubeService,
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
          update: (ctx, settingsVm, playerVm) =>
              playerVm ??
              PlayerViewModel(
                storage: storageService,
                youtubeService: youtubeService,
                settingsViewModel: settingsVm,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'TubeTune',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationView(),
      ),
    );
  }
}
