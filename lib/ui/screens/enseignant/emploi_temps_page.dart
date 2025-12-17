import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/emploi_temps.dart';
import '../../../../core/models/cours.dart';
import '../../../../core/models/enseignant.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';

class EmploiTempsPageContent extends StatefulWidget {
  const EmploiTempsPageContent({super.key});

  @override
  State<EmploiTempsPageContent> createState() => _EmploiTempsPageContentState();
}

class _EmploiTempsPageContentState extends State<EmploiTempsPageContent> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _emploisAvecDetails = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _vueActive = 'hebdomadaire'; // 'hebdomadaire' ou 'liste'
  String _selectedJour = 'Lundi';

  final List<String> _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi'
  ];

  @override
  void initState() {
    super.initState();
    _chargerEmploiTemps();
  }

  Future<void> _chargerEmploiTemps() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Récupérer l'enseignant connecté
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Enseignant) {
        setState(() {
          _errorMessage = 'Utilisateur non reconnu comme enseignant';
          _isLoading = false;
        });
        return;
      }

      final enseignantId = currentUser.id;

      // Charger les cours de l'enseignant
      final mesCours = await _firestoreService.getCoursParEnseignant(enseignantId);

      if (mesCours.isEmpty) {
        setState(() {
          _emploisAvecDetails = [];
          _isLoading = false;
        });
        return;
      }

      // Pour chaque cours, charger les emplois du temps associés
      final tousLesEmplois = <Map<String, dynamic>>[];

      for (final cours in mesCours) {
        try {
          // Cette méthode n'existe pas encore, nous allons la créer
          final emploisDuCours = await _firestoreService.getEmploiTempsParCours(cours.id);

          for (final emploi in emploisDuCours) {
            final details = await _firestoreService.getEmploiTempsAvecDetails(emploi.id);
            tousLesEmplois.add(details);
          }
        } catch (e) {
          print('Erreur chargement emploi temps pour cours ${cours.nom}: $e');
        }
      }

      setState(() {
        _emploisAvecDetails = tousLesEmplois;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de l\'emploi du temps: $e';
        _isLoading = false;
      });
    }
  }

  // Filtrer les emplois par jour
  List<Map<String, dynamic>> _getEmploisParJour(String jour) {
    return _emploisAvecDetails.where((item) {
      final emploiTemps = item['emploiTemps'] as EmploiTemps;
      return emploiTemps.jour == jour;
    }).toList();
  }

  // Trier les emplois par heure de début
  List<Map<String, dynamic>> _trierEmploisParHeure(List<Map<String, dynamic>> emplois) {
    emplois.sort((a, b) {
      final emploiA = a['emploiTemps'] as EmploiTemps;
      final emploiB = b['emploiTemps'] as EmploiTemps;

      final heureA = emploiA.heureDebut.hour * 60 + emploiA.heureDebut.minute;
      final heureB = emploiB.heureDebut.hour * 60 + emploiB.heureDebut.minute;

      return heureA.compareTo(heureB);
    });

    return emplois;
  }

  Widget _buildVueHebdomadaire() {
    return SingleChildScrollView(
      child: Column(
        children: _jours.map((jour) {
          final emploisDuJour = _trierEmploisParHeure(_getEmploisParJour(jour));

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCouleurJour(jour),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                jour,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${emploisDuJour.length} créneau(x)',
                style: TextStyle(color: Colors.grey[600]),
              ),
              children: [
                if (emploisDuJour.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun cours ce jour',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...emploisDuJour.map((item) => _buildCreneauCard(item)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVueListe() {
    final tousLesEmplois = _trierEmploisParHeure(_emploisAvecDetails);

    if (tousLesEmplois.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun créneau programmé',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tousLesEmplois.length,
      itemBuilder: (context, index) {
        final item = tousLesEmplois[index];
        return _buildCreneauCard(item);
      },
    );
  }

  Widget _buildCreneauCard(Map<String, dynamic> item) {
    final emploiTemps = item['emploiTemps'] as EmploiTemps;
    final cours = item['cours'] as Cours;
    final groupeNom = item['groupeNom'] as String;
    final filiereNom = item['filiereNom'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCouleurJour(emploiTemps.jour).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emploiTemps.jour.substring(0, 3),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getCouleurJour(emploiTemps.jour),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.access_time,
                size: 16,
                color: _getCouleurJour(emploiTemps.jour),
              ),
            ],
          ),
        ),
        title: Text(
          cours.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$filiereNom - $groupeNom'),
            Text('${emploiTemps.salle}'),
            Text(
              '${_formatTimeOfDay(emploiTemps.heureDebut)} - ${_formatTimeOfDay(emploiTemps.heureFin)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            '${emploiTemps.dureeMinutes ~/ 60}h${emploiTemps.dureeMinutes % 60}min',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getCouleurJour(emploiTemps.jour).withOpacity(0.2),
        ),
        onTap: () {
          _afficherDetailsCreneau(item);
        },
      ),
    );
  }

  Color _getCouleurJour(String jour) {
    final couleurs = {
      'Lundi': Colors.blue,
      'Mardi': Colors.green,
      'Mercredi': Colors.orange,
      'Jeudi': Colors.purple,
      'Vendredi': Colors.red,
      'Samedi': Colors.brown,
    };
    return couleurs[jour] ?? Colors.grey;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _afficherDetailsCreneau(Map<String, dynamic> item) {
    final emploiTemps = item['emploiTemps'] as EmploiTemps;
    final cours = item['cours'] as Cours;
    final groupeNom = item['groupeNom'] as String;
    final filiereNom = item['filiereNom'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du créneau'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Cours', cours.nom),
              _buildDetailItem('Filière', filiereNom),
              _buildDetailItem('Groupe', groupeNom),
              _buildDetailItem('Jour', emploiTemps.jour),
              _buildDetailItem('Horaire',
                  '${_formatTimeOfDay(emploiTemps.heureDebut)} - ${_formatTimeOfDay(emploiTemps.heureFin)}'),
              _buildDetailItem('Durée',
                  '${emploiTemps.dureeMinutes ~/ 60}h${emploiTemps.dureeMinutes % 60}min'),
              _buildDetailItem('Salle', emploiTemps.salle),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreCreneaux = _emploisAvecDetails.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Emploi du Temps'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emploi du temps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '$nombreCreneaux créneau(x) cette semaine',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch vue
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _vueActive = 'hebdomadaire'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _vueActive == 'hebdomadaire' ? Colors.green[700] : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: _vueActive == 'hebdomadaire' ? Colors.white : Colors.green[700],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _vueActive = 'liste'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _vueActive == 'liste' ? Colors.green[700] : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.list,
                            size: 16,
                            color: _vueActive == 'liste' ? Colors.white : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gestion des erreurs
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.red[800]),
                    onPressed: _chargerEmploiTemps,
                  ),
                ],
              ),
            ),
          ],

          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de votre emploi du temps...'),
                ],
              ),
            )
                : _vueActive == 'hebdomadaire'
                ? _buildVueHebdomadaire()
                : _buildVueListe(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chargerEmploiTemps,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
