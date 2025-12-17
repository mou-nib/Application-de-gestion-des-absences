import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/cours.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/enseignant.dart';

class MesCoursPageContent extends StatefulWidget {  // ← CHANGER LE NOM ICI
  const MesCoursPageContent({super.key});

  @override
  State<MesCoursPageContent> createState() => _MesCoursPageContentState();
}

class _MesCoursPageContentState extends State<MesCoursPageContent> {
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
    _chargerMesCours();
  }

  Future<void> _chargerMesCours() async {
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

      // Charger les cours de cet enseignant
      final cours = await _firestoreService.getCoursParEnseignant(enseignantId);

      // Charger les détails pour chaque cours
      final coursAvecDetails = <Map<String, dynamic>>[];
      for (final coursItem in cours) {
        final details = await _firestoreService.getCoursAvecDetails(coursItem.id);
        coursAvecDetails.add(details);
      }

      setState(() {
        _coursAvecDetails = coursAvecDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de vos cours: $e';
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

  Widget _buildCoursCard(Map<String, dynamic> item) {
    final cours = item['cours'] as Cours;
    final filiereNom = item['filiereNom'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCouleurNiveau(cours.niveau),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school, color: Colors.white, size: 20),
        ),
        title: Text(
          cours.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filière: $filiereNom'),
            Text('Niveau: ${cours.niveau}'),
            Text('Durée: ${cours.dureeHeures} heures'),
            if (cours.description.isNotEmpty)
              Text('Description: ${cours.description}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _afficherDetailsCours(item);
        },
      ),
    );
  }

  Color _getCouleurNiveau(String niveau) {
    final couleurs = {
      '1ère Année': Colors.blue,
      '2ème Année': Colors.green,
      '3ème Année': Colors.orange,
      '4ème Année': Colors.purple,
      '5ème Année': Colors.red,
    };
    return couleurs[niveau] ?? Colors.grey;
  }

  void _afficherDetailsCours(Map<String, dynamic> item) {
    final cours = item['cours'] as Cours;
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
              _buildDetailItem('Description',
                  cours.description.isNotEmpty ? cours.description : 'Aucune description'),
              _buildDetailItem('Filière', filiereNom),
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
        title: const Text('Mes Cours'),
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
          // Header avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes cours assignés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
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
                    onPressed: _chargerMesCours,
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
                  Text('Chargement de vos cours...'),
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
                    'Aucun cours assigné',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Vous n\'avez aucun cours assigné pour le moment',
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
        onPressed: _chargerMesCours,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
