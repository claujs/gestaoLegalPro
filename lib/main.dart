import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/di/locator.dart';
import 'core/controllers/theme_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/processes/presentation/pages/process_list_page.dart';
import 'features/processes/presentation/pages/process_detail_page.dart';
import 'features/agenda/presentation/pages/schedule_audience_page.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/processes/presentation/viewmodels/process_list_view_model.dart';
import 'features/processes/presentation/pages/process_create_page.dart';
import 'features/clients/presentation/pages/client_create_page.dart';
import 'features/clients/presentation/pages/client_list_page.dart';
import 'features/clients/data/process_client_link_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProcessClientLinkHiveAdapter());
  }
  setupLocator();
  Get.put(ThemeController());
  Get.put(AuthViewModel());
  Get.put(ProcessListViewModel());
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;

  ThemeController get _theme => Get.find();
  AuthViewModel get _auth => Get.find();

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: LoginPage.route,
      refreshListenable: Listenable.merge([
        // Poderíamos adicionar escuta para auth mudanças se necessário
      ]),
      redirect: (context, state) {
        final logged = _auth.isLoggedIn;
        final loggingIn = state.fullPath == LoginPage.route;
        if (!logged && !loggingIn) return LoginPage.route;
        if (logged && loggingIn) return DashboardPage.route;
        return null;
      },
      routes: [
        GoRoute(
          path: LoginPage.route,
          builder: (ctx, st) => LoginPage(onToggleTheme: _theme.toggle),
        ),
        GoRoute(
          path: DashboardPage.route,
          builder: (ctx, st) => const DashboardPage(),
          routes: [
            GoRoute(
              path: ProcessListPage.route.substring(1),
              builder: (ctx, st) => const ProcessListPage(),
              routes: [
                GoRoute(
                  path: 'processo',
                  name: 'processo_detalhe',
                  builder: (ctx, st) {
                    final args = st.extra as ProcessDetailArgs?;
                    return ProcessDetailPage(process: args!.process);
                  },
                ),
                GoRoute(
                  path: 'agendar',
                  builder: (ctx, st) => const ScheduleAudiencePage(),
                ),
                GoRoute(
                  path: 'novo',
                  name: 'processo_novo',
                  builder: (ctx, st) => const ProcessCreatePage(),
                ),
              ],
            ),
            GoRoute(
              path: '/dashboard/clientes',
              builder: (context, state) => const ClientListPage(),
            ),
            GoRoute(
              path: 'clientes/novo',
              name: 'cliente_novo',
              builder: (ctx, st) => const ClientCreatePage(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Gestão Legal Pro',
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('pt', 'BR'),
        themeMode: _theme.mode,
        theme: buildLightTheme(GoogleFonts.openSans),
        darkTheme: buildDarkTheme(GoogleFonts.openSans),
        routerConfig: _router,
      ),
    );
  }
}
