import 'package:abs_tracker_f/ui/screens/admin/admin_dashboard.dart';
import 'package:abs_tracker_f/ui/screens/enseignant/enseignant_dashboard.dart';
import 'package:abs_tracker_f/ui/screens/etudiant/etudiant_dashboard.dart';
import 'package:abs_tracker_f/ui/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../core/models/admin.dart';
import '../core/models/enseignant.dart';
import '../core/models/etudiant.dart';
import '../core/services/auth_service.dart';

class App extends StatelessWidget {
  final AuthService authService;

  const App({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Gestion des Absences',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: _buildHomeScreen(state, context),
        );
      },
    );
  }

  Widget _buildHomeScreen(AuthState state, BuildContext context) {
    if (state is AuthLoading) {
      return _buildLoadingScreen();
    }

    if (state is AuthAuthenticated) {
      return _redirectToDashboard(state.user);
    }

    // Par défaut, afficher l'écran de login
    return const LoginScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
            const SizedBox(height: 20),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _redirectToDashboard(dynamic user) {
    // Rediriger vers le dashboard selon le rôle
    if (user is Admin) {
      return const AdminDashboard();
    } else if (user is Enseignant) {
      return const EnseignantDashboard(); // À créer
    } else if (user is Etudiant) {
      return const EtudiantDashboard(); // À créer
    } else {
      // Fallback vers le login si rôle non reconnu
      return const LoginScreen();
    }
  }
}
