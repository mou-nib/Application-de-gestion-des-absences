import 'package:flutter/material.dart';
import '../../../../core/services/firestore_service.dart';
import 'filieres/liste_filieres_page.dart';

class GestionEtudiantsPage extends StatefulWidget {
  const GestionEtudiantsPage({super.key});

  @override
  State<GestionEtudiantsPage> createState() => _GestionEtudiantsPageState();
}

class _GestionEtudiantsPageState extends State<GestionEtudiantsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, int> _nombreEtudiantsParNiveau = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerNombreEtudiants();
  }

  Future<void> _chargerNombreEtudiants() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final niveaux = ['1ère Année', '2ème Année', '3ème Année', '4ème Année', '5ème Année'];

      for (final niveau in niveaux) {
        final nombre = await _firestoreService.getNombreEtudiantsParNiveau(niveau);
        _nombreEtudiantsParNiveau[niveau] = nombre;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur lors du chargement des effectifs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Étudiants',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez un niveau pour gérer les étudiants',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des effectifs...'),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildNiveauCard(
                      niveau: '1ère Année',
                      couleur: Colors.blue,
                      icon: Icons.looks_one,
                      onTap: () => _ouvrirListeFilieres(context, '1ère Année'),
                    ),
                    _buildNiveauCard(
                      niveau: '2ème Année',
                      couleur: Colors.green,
                      icon: Icons.looks_two,
                      onTap: () => _ouvrirListeFilieres(context, '2ème Année'),
                    ),
                    _buildNiveauCard(
                      niveau: '3ème Année',
                      couleur: Colors.orange,
                      icon: Icons.looks_3,
                      onTap: () => _ouvrirListeFilieres(context, '3ème Année'),
                    ),
                    _buildNiveauCard(
                      niveau: '4ème Année',
                      couleur: Colors.purple,
                      icon: Icons.looks_4,
                      onTap: () => _ouvrirListeFilieres(context, '4ème Année'),
                    ),
                    _buildNiveauCard(
                      niveau: '5ème Année',
                      couleur: Colors.red,
                      icon: Icons.looks_5,
                      onTap: () => _ouvrirListeFilieres(context, '5ème Année'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
        onPressed: _chargerNombreEtudiants,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Actualiser les effectifs',
      ),
    );
  }

  Widget _buildNiveauCard({
    required String niveau,
    required Color couleur,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final nombreEtudiants = _nombreEtudiantsParNiveau[niveau] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                couleur.withOpacity(0.1),
                couleur.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: couleur,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          niveau,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: couleur,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: 12,
                      color: couleur,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$nombreEtudiants',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: couleur,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'étudiants',
                      style: TextStyle(
                        fontSize: 9,
                        color: couleur,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gérer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 11,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirListeFilieres(BuildContext context, String niveau) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeFilieresPage(niveau: niveau),
      ),
    );
  }
}
