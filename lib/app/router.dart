import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/audits/presentation/home_shell.dart';
import '../features/audits/presentation/visit_workspace_page.dart';
import '../features/admin/presentation/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    // IMPORTANTISSIMO: gestiamo anche "/"
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          if (!auth.isAuthenticated) return '/login';
          return auth.isAdmin ? '/admin' : '/home';
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(
                curve: Curves.easeInOutCirc,
              ).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(
                curve: Curves.easeInOutCirc,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/visit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: VisitWorkspacePage(visitId: id),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          ),
                        ),
                    child: child,
                  );
                },
          );
        },
      ),
    ],

    redirect: (context, state) {
      final loc = state.matchedLocation;

      // lascia passare login e root (root poi redirige)
      final isPublic = loc == '/login' || loc == '/';
      if (!auth.isAuthenticated && !isPublic) return '/login';

      if (auth.isAuthenticated && loc == '/login') {
        return auth.isAdmin ? '/admin' : '/home';
      }
      
      if (auth.isAuthenticated && loc == '/home' && auth.isAdmin) {
        return '/admin'; // Un admin non deve vedere la home dell'ispettore
      }
      
      if (auth.isAuthenticated && loc == '/admin' && !auth.isAdmin) {
        return '/home'; // Un ispettore non deve vedere la dashboard admin
      }

      return null;
    },
  );
});
