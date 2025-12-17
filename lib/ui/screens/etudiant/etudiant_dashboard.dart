import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../core/models/etudiant.dart';
import '../../../../core/models/absence.dart';
import '../../../../core/models/emploi_temps.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../core/models/cours.dart';
import 'emploi_temps_etudiant_page.dart';
import 'mes_absences_page.dart';

class EtudiantDashboard extends StatefulWidget {
  const EtudiantDashboard({super.key});

  @override
  State<EtudiantDashboard> createState() => _EtudiantDashboardState();
}

class _EtudiantDashboardState extends State<EtudiantDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Pages du dashboard étudiant
  final List<Widget> _pages = [
    const EtudiantHomePage(),
    const EmploiTempsEtudiantPage(),
    const MesAbsencesPage(),
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
        Etudiant? etudiant;
        if (state is AuthAuthenticated && state.user is Etudiant) {
          etudiant = state.user as Etudiant;
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (etudiant != null) ...[
                  Text(
                    'Bienvenu, ${etudiant.prenom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Étudiant - ${etudiant.niveau}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[100],
                    ),
                  ),
                ] else
                  const Text(
                    'Étudiant',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            toolbarHeight: 80,
          ),
          drawer: _buildDrawer(context, etudiant),
          body: _pages[_selectedIndex],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, Etudiant? etudiant) {
    return Drawer(
      child: Column(
        children: [
          // Header du drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[700],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Text(
                          etudiant != null
                              ? '${etudiant.prenom[0]}${etudiant.nom[0]}'.toUpperCase()
                              : 'ET',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (etudiant != null) ...[
                              Text(
                                '${etudiant.prenom} ${etudiant.nom}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                etudiant.email,
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
                                  color: Colors.orange[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  etudiant.isActif ? 'ACTIF' : 'INACTIF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else
                              const Text(
                                'Étudiant',
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
                  icon: Icons.schedule,
                  title: 'Emploi du Temps',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.event_busy,
                  title: 'Mes Absences',
                  index: 2,
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
        color: _selectedIndex == index ? Colors.orange[700] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.orange[700] : Colors.grey[700],
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.orange[50],
      onTap: () => _onItemTapped(index),
    );
  }
}

// Page d'accueil étudiant avec données dynamiques
class EtudiantHomePage extends StatefulWidget {
  const EtudiantHomePage({super.key});

  @override
  State<EtudiantHomePage> createState() => _EtudiantHomePageState();
}

class _EtudiantHomePageState extends State<EtudiantHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic> _statistiques = {
    'cours_aujourdhui': 0,
    'absences_mois': 0,
    'prochain_cours': '--:--',
    'moyenne_presence': '0%',
  };
  List<Map<String, dynamic>> _prochainsCours = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerDonneesDashboard();
  }

  Future<void> _chargerDonneesDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Etudiant) {
        setState(() {
          _errorMessage = 'Utilisateur non reconnu comme étudiant';
          _isLoading = false;
        });
        return;
      }

      final etudiant = currentUser;
      await _chargerStatistiquesEtudiant(etudiant.id);
      await _chargerProchainsCours(etudiant.groupeId);
      await _chargerCoursAujourdhui(etudiant.groupeId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerStatistiquesEtudiant(String etudiantId) async {
    try {
      // Charger les statistiques des absences
      final statsAbsences = await _firestoreService.getStatistiquesAbsences(etudiantId);

      // Calculer la moyenne de présence
      final totalAbsences = statsAbsences['total'] ?? 0;
      final absencesJustifiees = (statsAbsences['justifiees'] ?? 0) + (statsAbsences['en_attente'] ?? 0);
      final tauxPresence = totalAbsences > 0
          ? ((totalAbsences - (statsAbsences['non_justifiees'] ?? 0)) / totalAbsences * 100).round()
          : 100;

      setState(() {
        _statistiques = {
          ..._statistiques,
          'absences_mois': statsAbsences['total'] ?? 0,
          'moyenne_presence': '$tauxPresence%',
        };
      });
    } catch (e) {
      print('Erreur chargement statistiques étudiant: $e');
    }
  }

  Future<void> _chargerProchainsCours(String groupeId) async {
    try {
      final maintenant = DateTime.now();
      final aujourdhui = _getNomJour(maintenant.weekday);
      final heureActuelle = TimeOfDay.fromDateTime(maintenant);

      // Charger l'emploi du temps du groupe
      final emplois = await _firestoreService.getEmploiTempsParGroupe(groupeId);
      final emploisAujourdhui = emplois.where((emploi) => emploi.jour == aujourdhui).toList();

      // Trier par heure de début et trouver le prochain cours
      emploisAujourdhui.sort((a, b) {
        final heureA = a.heureDebut.hour * 60 + a.heureDebut.minute;
        final heureB = b.heureDebut.hour * 60 + b.heureDebut.minute;
        return heureA.compareTo(heureB);
      });

      final prochainCours = emploisAujourdhui.firstWhere(
            (emploi) {
          final heureDebut = emploi.heureDebut.hour * 60 + emploi.heureDebut.minute;
          final heureActuelleMinutes = heureActuelle.hour * 60 + heureActuelle.minute;
          return heureDebut > heureActuelleMinutes;
        },
        orElse: () => emploisAujourdhui.isNotEmpty ? emploisAujourdhui.first : EmploiTemps(
          id: '',
          groupeId: '',
          coursId: '',
          jour: '',
          heureDebut: const TimeOfDay(hour: 0, minute: 0),
          heureFin: const TimeOfDay(hour: 0, minute: 0),
          salle: '',
          dateCreation: DateTime.now(),
        ),
      );

      // Charger les détails des cours pour l'affichage
      final prochainsCoursAvecDetails = <Map<String, dynamic>>[];
      for (final emploi in emploisAujourdhui) {
        try {
          final details = await _firestoreService.getEmploiTempsAvecDetails(emploi.id);
          prochainsCoursAvecDetails.add(details);
        } catch (e) {
          print('Erreur chargement détails cours ${emploi.id}: $e');
        }
      }

      setState(() {
        _prochainsCours = prochainsCoursAvecDetails;
        if (prochainCours.id.isNotEmpty) {
          _statistiques['prochain_cours'] = _formatTimeOfDay(prochainCours.heureDebut);
        }
      });
    } catch (e) {
      print('Erreur chargement prochains cours: $e');
    }
  }

  Future<void> _chargerCoursAujourdhui(String groupeId) async {
    try {
      final aujourdhui = _getNomJour(DateTime.now().weekday);
      final emplois = await _firestoreService.getEmploiTempsParGroupe(groupeId);
      final coursAujourdhui = emplois.where((emploi) => emploi.jour == aujourdhui).length;

      setState(() {
        _statistiques['cours_aujourdhui'] = coursAujourdhui;
      });
    } catch (e) {
      print('Erreur chargement cours aujourd\'hui: $e');
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
    final enseignantNom = item['enseignantNom'] as String;

    final maintenant = TimeOfDay.now();
    final heureDebutMinutes = emploiTemps.heureDebut.hour * 60 + emploiTemps.heureDebut.minute;
    final maintenantMinutes = maintenant.hour * 60 + maintenant.minute;

    final estEnCours = maintenantMinutes >= heureDebutMinutes &&
        maintenantMinutes < heureDebutMinutes + emploiTemps.dureeMinutes;
    final estPasse = maintenantMinutes > heureDebutMinutes + emploiTemps.dureeMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: estEnCours ? Colors.green[50] : (estPasse ? Colors.grey[200] : Colors.blue[50]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            estEnCours ? Icons.play_arrow : (estPasse ? Icons.check : Icons.schedule),
            color: estEnCours ? Colors.green : (estPasse ? Colors.grey : Colors.blue),
          ),
        ),
        title: Text(
          cours.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$enseignantNom • ${emploiTemps.salle}'),
            Text('${_formatTimeOfDay(emploiTemps.heureDebut)} - ${_formatTimeOfDay(emploiTemps.heureFin)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: estEnCours ? Colors.green[100] : (estPasse ? Colors.grey[300] : Colors.blue[100]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            estEnCours ? 'En cours' : (estPasse ? 'Terminé' : 'À venir'),
            style: TextStyle(
              fontSize: 10,
              color: estEnCours ? Colors.green[800] : (estPasse ? Colors.grey[700] : Colors.blue[800]),
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
                color: Colors.orange[700],
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
                      Text('Chargement de vos données...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _chargerDonneesDashboard,
                        child: const Text('Réessayer'),
                      ),
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
                          title: 'Cours Aujourd\'hui',
                          value: _statistiques['cours_aujourdhui'] ?? 0,
                          icon: Icons.book,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'Absences ce Mois',
                          value: _statistiques['absences_mois'] ?? 0,
                          icon: Icons.event_busy,
                          color: Colors.red,
                        ),
                        _buildStatCard(
                          title: 'Prochain Cours',
                          value: _statistiques['prochain_cours'] ?? '--:--',
                          icon: Icons.schedule,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          title: 'Moyenne Présence',
                          value: _statistiques['moyenne_presence'] ?? '0%',
                          icon: Icons.percent,
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Cours d'aujourd'hui
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cours aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _prochainsCours.isEmpty
                                    ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_available, size: 60, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Aucun cours aujourd\'hui',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                                    : ListView.builder(
                                  itemCount: _prochainsCours.length,
                                  itemBuilder: (context, index) {
                                    return _buildCoursItem(_prochainsCours[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chargerDonneesDashboard,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Actualiser',
      ),
    );
  }
}

// Pages du dashboard étudiant
class EmploiTempsEtudiantPage extends StatelessWidget {
  const EmploiTempsEtudiantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmploiTempsEtudiantContent();
  }
}

class MesAbsencesPage extends StatelessWidget {
  const MesAbsencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MesAbsencesContent();
  }
}
