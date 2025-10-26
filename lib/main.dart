import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/cupertino_theme_provider.dart';
import 'core/supabase_config.dart';
import 'pages/home_page.dart';
import 'pages/analytics_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
// import 'widgets/receipt_add_sheet.dart';
import 'package:ticket_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(const ProviderScope(child: TicketApp()));
}

class TicketApp extends ConsumerWidget {
  const TicketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cupertinoTheme = ref.watch(cupertinoThemeProvider);
    
    return CupertinoApp(
      title: 'Ticket App',
      theme: cupertinoTheme,
      home: const AuthWrapper(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en'), Locale('ru')],
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Session?>(
      stream: Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        
        final session = snapshot.data;
        if (session == null) {
          return const LoginPage();
        }
        
        return const HomeShell();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(CupertinoIcons.list_bullet),
            ),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(CupertinoIcons.chart_bar),
            ),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(CupertinoIcons.gear),
            ),
          ),
        ],
        height: 40,
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              key: const ValueKey('home_tab'),
              builder: (_) => const HomePage(),
            );
          case 1:
            return CupertinoTabView(
              key: const ValueKey('analytics_tab'),
              builder: (_) => const AnalyticsPage(),
            );
          case 2:
          default:
            return CupertinoTabView(
              key: const ValueKey('profile_tab'),
              builder: (_) => const ProfilePage(),
            );
        }
      },
    );
  }
}

