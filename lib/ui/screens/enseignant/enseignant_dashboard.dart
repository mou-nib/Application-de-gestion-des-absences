import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../core/models/enseignant.dart';
import '../../../../core/models/cours.dart';
import '../../../../core/models/emploi_temps.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';
import 'emploi_temps_page.dart';
import 'gestion_absences_page.dart';
import 'mes_cours_page.dart';

class EnseignantDashboard extends StatefulWidget {
  const EnseignantDashboard({super.key});

  @override
  State<EnseignantDashboard> createState() => _EnseignantDashboardState();
}

class _EnseignantDashboardState extends State<EnseignantDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Pages du dashboard enseignant
  final List<Widget> _pages = [
    const EnseignantHomePage(),
    const MesCoursPage(),
    const GestionAbsencesPage(),
    const EmploiTempsPage(),
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
        Enseignant? enseignant;
        if (state is AuthAuthenticated && state.user is Enseignant) {
          enseignant = state.user as Enseignant;
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enseignant != null) ...[
                  Text(
                    'Bienvenu, ${enseignant.prenom} ${enseignant.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Enseignant',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[100],
                    ),
                  ),
                ] else
                  const Text(
                    'Enseignant',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            toolbarHeight: 80,
          ),
          drawer: _buildDrawer(context, enseignant),
          body: _pages[_selectedIndex],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, Enseignant? enseignant) {
    return Drawer(
      child: Column(
        children: [
          // Header du drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.school,
                          size: 30,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (enseignant != null) ...[
                              Text(
                                '${enseignant.prenom} ${enseignant.nom}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enseignant.email,
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
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  enseignant.isActif ? 'ACTIF' : 'INACTIF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else
                              const Text(
                                'Enseignant',
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
                  icon: Icons.book,
                  title: 'Mes Cours',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.event_busy,
                  title: 'Gestion Absences',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.schedule,
                  title: 'Emploi du Temps',
                  index: 3,
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
        color: _selectedIndex == index ? Colors.green[700] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.green[700] : Colors.grey[700],
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.green[50],
      onTap: () => _onItemTapped(index),
    );
  }
}

// Page d'accueil enseignant avec statistiques dynamiques
class EnseignantHomePage extends StatefulWidget {
  const EnseignantHomePage({super.key});

  @override
  State<EnseignantHomePage> createState() => _EnseignantHomePageState();
}

class _EnseignantHomePageState extends State<EnseignantHomePage> {
  Map<String, dynamic> _statistiques = {
    'cours': 0,
    'etudiants': 0,
    'absences_mois': 0,
    'prochains_cours': 0,
  };
  bool _isLoading = true;
  List<Map<String, dynamic>> _prochainsCours = [];

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
    _chargerProchainsCours();
  }

  Future<void> _chargerStatistiques() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is Enseignant) {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        final stats = await firestoreService.getStatistiquesEnseignant(currentUser.id);

        setState(() {
          _statistiques = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement statistiques enseignant: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerProchainsCours() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Enseignant) return;

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // Récupérer les cours de l'enseignant
      final mesCours = await firestoreService.getCoursParEnseignant(currentUser.id);
      final coursIds = mesCours.map((c) => c.id).toList();

      if (coursIds.isEmpty) {
        setState(() {
          _prochainsCours = [];
        });
        return;
      }

      // Récupérer l'emploi du temps d'aujourd'hui
      final aujourdhui = _getNomJour(DateTime.now().weekday);
      final maintenant = TimeOfDay.now();
      final prochainsCours = <Map<String, dynamic>>[];

      for (final coursId in coursIds) {
        final emplois = await firestoreService.getEmploiTempsParCours(coursId);
        final emploisAujourdhui = emplois.where((emploi) => emploi.jour == aujourdhui).toList();

        for (final emploi in emploisAujourdhui) {
          final heureDebutMinutes = emploi.heureDebut.hour * 60 + emploi.heureDebut.minute;
          final maintenantMinutes = maintenant.hour * 60 + maintenant.minute;

          // Cours qui n'ont pas encore commencé ou en cours
          if (maintenantMinutes < heureDebutMinutes + emploi.dureeMinutes) {
            final details = await firestoreService.getEmploiTempsAvecDetails(emploi.id);
            prochainsCours.add(details);
          }
        }
      }

      // Trier par heure de début
      prochainsCours.sort((a, b) {
        final emploiA = a['emploiTemps'] as EmploiTemps;
        final emploiB = b['emploiTemps'] as EmploiTemps;

        final heureA = emploiA.heureDebut.hour * 60 + emploiA.heureDebut.minute;
        final heureB = emploiB.heureDebut.hour * 60 + emploiB.heureDebut.minute;

        return heureA.compareTo(heureB);
      });

      setState(() {
        _prochainsCours = prochainsCours;
      });
    } catch (e) {
      print('Erreur chargement prochains cours: $e');
    }
  }

  String _getNomJour(int weekday) {
    final jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return jours[weekday];
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatCard({
    required String title,
    required dynamic value,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursItem(Map<String, dynamic> item) {
    final emploiTemps = item['emploiTemps'] as EmploiTemps;
    final cours = item['cours'] as Cours;
    final groupeNom = item['groupeNom'] as String;

    final maintenant = TimeOfDay.now();
    final heureDebutMinutes = emploiTemps.heureDebut.hour * 60 + emploiTemps.heureDebut.minute;
    final maintenantMinutes = maintenant.hour * 60 + maintenant.minute;

    final estEnCours = maintenantMinutes >= heureDebutMinutes &&
        maintenantMinutes < heureDebutMinutes + emploiTemps.dureeMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: estEnCours ? Colors.green[50] : Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            estEnCours ? Icons.play_arrow : Icons.schedule,
            color: estEnCours ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          cours.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$groupeNom • ${emploiTemps.salle}'),
            Text('${_formatTimeOfDay(emploiTemps.heureDebut)} - ${_formatTimeOfDay(emploiTemps.heureFin)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: estEnCours ? Colors.green[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            estEnCours ? 'En cours' : 'À venir',
            style: TextStyle(
              fontSize: 10,
              color: estEnCours ? Colors.green[800] : Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
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
                color: Colors.green[700],
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
                          title: 'Cours Actifs',
                          value: _statistiques['cours'] ?? 0,
                          icon: Icons.book,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          title: 'Étudiants',
                          value: _statistiques['etudiants'] ?? 0,
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'Absences ce Mois',
                          value: _statistiques['absences_mois'] ?? 0,
                          icon: Icons.event_busy,
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          title: 'Prochains Cours',
                          value: _statistiques['prochains_cours'] ?? 0,
                          icon: Icons.schedule,
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Prochains cours aujourd'hui
                    if (_prochainsCours.isNotEmpty) ...[
                      Text(
                        'Cours aujourd\'hui',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView.builder(
                              itemCount: _prochainsCours.length,
                              itemBuilder: (context, index) {
                                return _buildCoursItem(_prochainsCours[index]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ] else if (!_isLoading) ...[
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.event_available, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun cours aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _chargerStatistiques();
          _chargerProchainsCours();
        },
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Actualiser',
      ),
    );
  }
}

// Pages du dashboard enseignant
class MesCoursPage extends StatelessWidget {
  const MesCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MesCoursPageContent();
  }
}

class GestionAbsencesPage extends StatelessWidget {
  const GestionAbsencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GestionAbsencesPageContent();
  }
}

class EmploiTempsPage extends StatelessWidget {
  const EmploiTempsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmploiTempsPageContent();
  }
}
