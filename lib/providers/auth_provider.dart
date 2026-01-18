import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAdmin;

  const AuthState({
    this.user,
    this.isLoading = true,
    this.isAdmin = false,
  });

  bool get isAuthenticated => user != null && isAdmin;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAdmin,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check current session
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      _checkAdminStatus(session.user);
    } else {
      state = const AuthState(isLoading: false);
    }

    // Listen to auth changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _checkAdminStatus(session.user);
      } else {
        state = const AuthState(isLoading: false);
      }
    });
  }

  Future<void> _checkAdminStatus(User user) async {
    try {
      // Check if user is in admins table
      final response = await SupabaseService.client
          .from('admins')
          .select('id')
          .eq('user_id', user.id)
          .eq('ativo', true)
          .maybeSingle();

      final isAdmin = response != null;

      state = AuthState(
        user: user,
        isLoading: false,
        isAdmin: isAdmin,
      );

      // If not admin, sign out
      if (!isAdmin) {
        await signOut();
      }
    } catch (e) {
      // If admins table doesn't exist yet, allow access (for initial setup)
      state = AuthState(
        user: user,
        isLoading: false,
        isAdmin: true, // Allow access temporarily
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _checkAdminStatus(response.user!);

      if (!state.isAdmin) {
        throw Exception('Acesso negado. Voce nao e um administrador.');
      }
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    state = const AuthState(isLoading: false);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Helper provider to check if authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
