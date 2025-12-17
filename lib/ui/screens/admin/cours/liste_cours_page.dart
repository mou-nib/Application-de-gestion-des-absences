import 'package:flutter/material.dart';
import '../../../../../core/models/cours.dart';
import '../../../../../core/services/firestore_service.dart';
import 'ajouter_cours_dialog.dart';

class ListeCoursPage extends StatefulWidget {
  const ListeCoursPage({super.key});

  @override
  State<ListeCoursPage> createState() => _ListeCoursPageState();
}

class _ListeCoursPageState extends State<ListeCoursPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _coursAvecDetails = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtreNiveau = 'Tous';

  final List<String> _niveaux = [
    'Tous',
    '1ère Année',
    '2ème Année',
    '3ème Année',
    '4ème Année',
    '5ème Année'
  ];

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  Future<void> _chargerCours() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final coursStream = _firestoreService.getCoursAvecDetailsStream();
      final subscription = coursStream.listen((coursList) {
        setState(() {
          _coursAvecDetails = coursList;
          _isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $error';
          _isLoading = false;
        });
      });

      // Garder la subscription active
      await subscription.asFuture();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des cours: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCoursFiltres() {
    if (_filtreNiveau == 'Tous') {
      return _coursAvecDetails;
    }
    return _coursAvecDetails.where((item) {
      final cours = item['cours'] as Cours;
      return cours.niveau == _filtreNiveau;
    }).toList();
  }

  void _ajouterCours() {
    showDialog(
      context: context,
      builder: (context) => const AjouterCoursDialog(),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours ajouté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _modifierCours(Cours cours) {
    showDialog(
      context: context,
      builder: (context) => AjouterCoursDialog(cours: cours),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cours "${cours.nom}" modifié avec succès'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _supprimerCours(Cours cours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Êtes-vous sûr de vouloir supprimer le cours "${cours.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerCours(cours.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cours "${cours.nom}" supprimé avec succès'),
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

  Widget _buildCoursCard(Map<String, dynamic> item) {
    final cours = item['cours'] as Cours;
    final enseignantNom = item['enseignantNom'] as String;
    final filiereNom = item['filiereNom'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school, color: Colors.purple[700]),
        ),
        title: Text(
          cours.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filière: $filiereNom'),
            Text('Enseignant: $enseignantNom'),
            Text('Niveau: ${cours.niveau}'),
            Text('Durée: ${cours.dureeHeures} heures'),
            if (cours.description.isNotEmpty)
              Text('Description: ${cours.description}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'modifier') {
              _modifierCours(cours);
            } else if (value == 'supprimer') {
              _supprimerCours(cours);
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
          _afficherDetailsCours(item);
        },
      ),
    );
  }

  void _afficherDetailsCours(Map<String, dynamic> item) {
    final cours = item['cours'] as Cours;
    final enseignantNom = item['enseignantNom'] as String;
    final filiereNom = item['filiereNom'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du cours'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nom du cours', cours.nom),
              _buildDetailItem('Description', cours.description.isNotEmpty ? cours.description : 'Aucune description'),
              _buildDetailItem('Filière', filiereNom),
              _buildDetailItem('Enseignant', enseignantNom),
              _buildDetailItem('Niveau', cours.niveau),
              _buildDetailItem('Durée', '${cours.dureeHeures} heures'),
              _buildDetailItem('Date de création',
                  '${cours.dateCreation.day}/${cours.dateCreation.month}/${cours.dateCreation.year}'),
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
    final coursFiltres = _getCoursFiltres();
    final totalHeures = coursFiltres.fold<int>(
        0, (sum, item) => sum + (item['cours'] as Cours).dureeHeures
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
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
          // Header avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.purple[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liste des cours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      Text(
                        '${coursFiltres.length} cours(s) - Total: ${totalHeures}h',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtre
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownButtonFormField<String>(
                value: _filtreNiveau,
                decoration: const InputDecoration(
                  labelText: 'Filtrer par niveau',
                  border: OutlineInputBorder(),
                ),
                items: _niveaux.map((niveau) {
                  return DropdownMenuItem(
                    value: niveau,
                    child: Text(niveau),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filtreNiveau = value!;
                  });
                },
              ),
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
                    onPressed: _chargerCours,
                  ),
                ],
              ),
            ),
          ],

          // Liste des cours
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des cours...'),
                ],
              ),
            )
                : coursFiltres.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun cours trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Ajoutez des cours pour les voir apparaître ici',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: coursFiltres.length,
              itemBuilder: (context, index) {
                final item = coursFiltres[index];
                return _buildCoursCard(item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterCours,
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
