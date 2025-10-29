import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:siparis_app/chatbot/chatbot_page.dart';
import 'package:siparis_app/community_page.dart';
import 'package:siparis_app/login_page.dart';
import 'package:siparis_app/profile_page.dart';
import 'package:siparis_app/register_page.dart';
import 'package:siparis_app/theme.dart';
import 'package:siparis_app/theme_provider.dart';
import 'package:siparis_app/women_challenge_page.dart';
import 'package:siparis_app/women_map_page.dart';
import 'order_list.dart';
import 'splash_screen_1.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Dahlias',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          // navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          routes: {
            '/': (context) => const SplashScreen(),
            '/orders': (context) => OrderListPage(),
            '/register': (context) => RegisterPage(),
            '/login': (context) => LoginPage(),
            '/profile': (context) => ProfilePage(),
            '/women_in_challenge': (context) => WomenChallengePage(),
            'api/women-map': (context) => const WomenMapPage(),
            'api/community': (context) => CommunityPage(),
            '/chatbot': (context) => const ChatbotPage(),
            '/challenges': (context) => const WomenChallengePage(),
          },
        );
      },
    );
  }
}

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // veya istediğiniz özel overscroll davranışı
  }
}
