import 'package:flutter/material.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/models/emploi_temps.dart';
import '../../../../../core/services/firestore_service.dart';
import '../../../../core/models/cours.dart';
import 'ajouter_emploi_temps_dialog.dart';
import 'vue_hebdomadaire_emploi_temps.dart';

class GestionEmploiTempsPage extends StatefulWidget {
  final Groupe groupe;

  const GestionEmploiTempsPage({super.key, required this.groupe});

  @override
  State<GestionEmploiTempsPage> createState() => _GestionEmploiTempsPageState();
}

class _GestionEmploiTempsPageState extends State<GestionEmploiTempsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _emploisAvecDetails = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _vueActive = 'hebdomadaire'; // 'hebdomadaire' ou 'liste'

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

      final emploisStream = _firestoreService.getEmploiTempsAvecDetailsStream(widget.groupe.id);
      final subscription = emploisStream.listen((emploisList) {
        setState(() {
          _emploisAvecDetails = emploisList;
          _isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $error';
          _isLoading = false;
        });
      });

      await subscription.asFuture();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des emplois du temps: $e';
        _isLoading = false;
      });
    }
  }

  void _ajouterEmploiTemps() {
    showDialog(
      context: context,
      builder: (context) => AjouterEmploiTempsDialog(
        groupe: widget.groupe,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Créneau ajouté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _modifierEmploiTemps(EmploiTemps emploiTemps) {
    showDialog(
      context: context,
      builder: (context) => AjouterEmploiTempsDialog(
        groupe: widget.groupe,
        emploiTemps: emploiTemps,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Créneau modifié avec succès'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _supprimerEmploiTemps(EmploiTemps emploiTemps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le créneau'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce créneau ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerEmploiTemps(emploiTemps.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Créneau supprimé avec succès'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildListeEmploiTemps() {
    if (_emploisAvecDetails.isEmpty) {
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
            Text(
              'Ajoutez des créneaux pour les voir apparaître ici',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Trier par jour et heure
    _emploisAvecDetails.sort((a, b) {
      final emploiA = a['emploiTemps'] as EmploiTemps;
      final emploiB = b['emploiTemps'] as EmploiTemps;

      final joursOrder = {'Lundi': 1, 'Mardi': 2, 'Mercredi': 3, 'Jeudi': 4, 'Vendredi': 5, 'Samedi': 6};
      final orderA = joursOrder[emploiA.jour] ?? 7;
      final orderB = joursOrder[emploiB.jour] ?? 7;

      if (orderA != orderB) return orderA.compareTo(orderB);

      final heureA = emploiA.heureDebut.hour * 60 + emploiA.heureDebut.minute;
      final heureB = emploiB.heureDebut.hour * 60 + emploiB.heureDebut.minute;
      return heureA.compareTo(heureB);
    });

    return ListView.builder(
      itemCount: _emploisAvecDetails.length,
      itemBuilder: (context, index) {
        final item = _emploisAvecDetails[index];
        final emploiTemps = item['emploiTemps'] as EmploiTemps;
        final cours = item['cours'] as Cours;
        final enseignantNom = item['enseignantNom'] as String;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCouleurJour(emploiTemps.jour),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              cours.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$enseignantNom - ${emploiTemps.salle}'),
                Text('${emploiTemps.jour} • ${emploiTemps.heureDebut.format(context)} - ${emploiTemps.heureFin.format(context)}'),
                Text('Durée: ${emploiTemps.dureeMinutes ~/ 60}h${emploiTemps.dureeMinutes % 60}min'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'modifier') {
                  _modifierEmploiTemps(emploiTemps);
                } else if (value == 'supprimer') {
                  _supprimerEmploiTemps(emploiTemps);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'modifier',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'supprimer',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              _afficherDetailsCreneau(item);
            },
          ),
        );
      },
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

  void _afficherDetailsCreneau(Map<String, dynamic> item) {
    final emploiTemps = item['emploiTemps'] as EmploiTemps;
    final cours = item['cours'] as Cours;
    final enseignantNom = item['enseignantNom'] as String;
    final filiereNom = item['filiereNom'] as String;
    final groupeNom = item['groupeNom'] as String;

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
              _buildDetailItem('Enseignant', enseignantNom),
              _buildDetailItem('Filière', filiereNom),
              _buildDetailItem('Groupe', groupeNom),
              _buildDetailItem('Jour', emploiTemps.jour),
              _buildDetailItem('Horaire', '${emploiTemps.heureDebut.format(context)} - ${emploiTemps.heureFin.format(context)}'),
              _buildDetailItem('Durée', '${emploiTemps.dureeMinutes ~/ 60}h${emploiTemps.dureeMinutes % 60}min'),
              _buildDetailItem('Salle', emploiTemps.salle),
              _buildDetailItem('Date création', '${emploiTemps.dateCreation.day}/${emploiTemps.dateCreation.month}/${emploiTemps.dateCreation.year}'),
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
        title: Text('Emploi du Temps - ${widget.groupe.nom}'),
        backgroundColor: Colors.purple[800],
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
                Icon(Icons.schedule, color: Colors.purple[800]),
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
                          color: Colors.purple[800],
                        ),
                      ),
                      Text(
                        '$nombreCreneaux créneau(x) programmé(s)',
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
                    border: Border.all(color: Colors.purple[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _vueActive = 'hebdomadaire'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _vueActive == 'hebdomadaire' ? Colors.purple[800] : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: _vueActive == 'hebdomadaire' ? Colors.white : Colors.purple[800],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _vueActive = 'liste'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _vueActive == 'liste' ? Colors.purple[800] : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.list,
                            size: 16,
                            color: _vueActive == 'liste' ? Colors.white : Colors.purple[800],
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
                  Text('Chargement de l\'emploi du temps...'),
                ],
              ),
            )
                : _vueActive == 'hebdomadaire'
                ? VueHebdomadaireEmploiTemps(
              groupe: widget.groupe,
              emploisAvecDetails: _emploisAvecDetails,
              onCreneauTap: _modifierEmploiTemps,
            )
                : _buildListeEmploiTemps(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEmploiTemps,
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
