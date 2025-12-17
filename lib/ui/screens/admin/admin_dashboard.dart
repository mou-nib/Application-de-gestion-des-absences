import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../core/models/admin.dart';
import '../../../../core/services/firestore_service.dart';
import 'cours/liste_cours_page.dart';
import 'enseignants/liste_enseignants_page.dart';
import 'gestion_etudiants_page.dart';
import 'justifications/gestion_justifications_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Pages du dashboard
  final List<Widget> _pages = [
    const AdminHomePage(),
    const GestionEtudiantsPage(),
    const GestionEnseignantsPage(),
    const GestionCoursPage(),
    const GestionJustificationsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        Admin? admin;
        if (state is AuthAuthenticated && state.user is Admin) {
          admin = state.user as Admin;
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (admin != null) ...[
                  Text(
                    'Bienvenu, ${admin.prenom} ${admin.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ] else
                  const Text(
                    'Administrateur',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            toolbarHeight: 80, // Augmenter la hauteur pour accommoder les deux lignes
          ),
          drawer: _buildDrawer(context, admin),
          body: _pages[_selectedIndex],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, Admin? admin) {
    return Drawer(
      child: Column(
        children: [
          // Header du drawer avec fond bleu complet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[800],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar et informations
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (admin != null) ...[
                              Text(
                                '${admin.prenom} ${admin.nom}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                admin.email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else
                              const Text(
                                'Administrateur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),

          // Menu de navigation
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'MENU PRINCIPAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de Bord',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Gestion Étudiants',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Gestion Enseignants',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.book,
                  title: 'Gestion Cours',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.pending_actions,
                  title: 'Justifications',
                  index: 4,
                ),
              ],
            ),
          ),

          // Section déconnexion
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue[800] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.blue[800] : Colors.grey[700],
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blue[50],
      onTap: () => _onItemTapped(index),
    );
  }
}

// AdminHomePage avec statistiques dynamiques
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Map<String, dynamic> _statistiques = {
    'etudiants': 0,
    'enseignants': 0,
    'cours': 0,
    'absences_mois': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
  }

  Future<void> _chargerStatistiques() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final stats = await firestoreService.getStatistiquesAdmin();

      setState(() {
        _statistiques = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement statistiques: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de Bord',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des statistiques...'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Cartes de statistiques
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Étudiants',
                          value: _statistiques['etudiants'] ?? 0,
                          icon: Icons.school,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          title: 'Enseignants',
                          value: _statistiques['enseignants'] ?? 0,
                          icon: Icons.person,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'Cours',
                          value: _statistiques['cours'] ?? 0,
                          icon: Icons.book,
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          title: 'Absences ce mois',
                          value: _statistiques['absences_mois'] ?? 0,
                          icon: Icons.event_busy,
                          color: Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bouton d'actualisation
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _chargerStatistiques,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser les statistiques'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GestionEnseignantsPage extends StatelessWidget {
  const GestionEnseignantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListeEnseignantsPage();
  }
}

class GestionCoursPage extends StatelessWidget {
  const GestionCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListeCoursPage();
  }
}

class GestionJustificationsPage extends StatelessWidget {
  const GestionJustificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GestionJustificationsPageContent();
  }
}
