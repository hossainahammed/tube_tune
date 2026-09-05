import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/services/background_audio_service.dart';
import 'core/services/cast_service.dart';
import 'core/services/download_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/timer_service.dart';
import 'core/services/youtube_service.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/player_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/subscriptions_viewmodel.dart';

import 'package:just_audio_background/just_audio_background.dart';

import 'viewmodels/shorts_viewmodel.dart';
import 'views/main_navigation_view.dart';
import 'core/responsive/responsive_centered_wrapper.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile-only foreground services & system UI styling
  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.tubetune.app.channel.audio',
        androidNotificationChannelName: 'TubeTune Background Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_bg_music',
      );
    } catch (_) {}

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Initialize Core Services
  final storageService = await StorageService.getInstance();
  final timerService = await TimerService.getInstance(storageService);
  final authService = await AuthService.getInstance(storageService);
  final subscriptionService = await SubscriptionService.getInstance(
    storageService,
  );
  final youtubeService = YoutubeService.instance;
  if (!kIsWeb) {
    await DownloadService.instance.init();
  }

  // Handle immediate global halt of all running media when auto-lock or schedule-lock triggers
  TimerService.onLockTriggered = () {
    try {
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      BackgroundAudioService.instance.stop();
    } catch (_) {}
  };

  runApp(
    TubeTuneApp(
      storageService: storageService,
      timerService: timerService,
      authService: authService,
      subscriptionService: subscriptionService,
      youtubeService: youtubeService,
    ),
  );
}

class TubeTuneApp extends StatelessWidget {
  final StorageService storageService;
  final TimerService timerService;
  final AuthService authService;
  final SubscriptionService subscriptionService;
  final YoutubeService youtubeService;

  const TubeTuneApp({
    super.key,
    required this.storageService,
    required this.timerService,
    required this.authService,
    required this.subscriptionService,
    required this.youtubeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timerService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: subscriptionService),
        ChangeNotifierProvider.value(value: CastService.instance),
        ChangeNotifierProvider.value(value: NotificationService.instance),
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
            storageService: storageService,
          ),
          update: (ctx, settingsVm, homeVm) =>
              homeVm ??
              HomeViewModel(
                youtubeService: youtubeService,
                settingsViewModel: settingsVm,
                storageService: storageService,
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
        ChangeNotifierProxyProvider2<
          SettingsViewModel,
          SubscriptionService,
          SubscriptionsViewModel
        >(
          create: (ctx) => SubscriptionsViewModel(
            youtubeService: youtubeService,
            subscriptionService: subscriptionService,
            settingsViewModel: ctx.read<SettingsViewModel>(),
          ),
          update: (ctx, settingsVm, subService, subVm) =>
              subVm ??
              SubscriptionsViewModel(
                youtubeService: youtubeService,
                subscriptionService: subService,
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
        navigatorKey: appNavigatorKey,
        title: 'TubeTune',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return ResponsiveCenteredWrapper(child: child ?? const SizedBox());
        },
        home: const MainNavigationView(),
      ),
    );
  }
}
