import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'services/supabase_service.dart';
import 'widgets/admin_shell.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/clientes/clientes_screen.dart';
import 'screens/prestadores/prestadores_screen.dart';
import 'screens/chamados/chamados_screen.dart';
import 'screens/pagamentos/pagamentos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: AdminApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesScreen(),
          ),
          GoRoute(
            path: '/prestadores',
            builder: (context, state) => const PrestadoresScreen(),
          ),
          GoRoute(
            path: '/chamados',
            builder: (context, state) => const ChamadosScreen(),
          ),
          GoRoute(
            path: '/pagamentos',
            builder: (context, state) => const PagamentosScreen(),
          ),
        ],
      ),
    ],
  );
});

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Seguro Pneu Pro - Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      routerConfig: router,
    );
  }
}
