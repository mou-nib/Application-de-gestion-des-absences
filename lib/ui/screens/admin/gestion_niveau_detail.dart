import 'package:abs_tracker_f/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/groupe.dart';
import '../../../core/services/firestore_service.dart';
import 'emploi_temps/gestion_emploi_temps_page.dart';
import 'etudiants/ajouter_etudiant_dialog.dart';
import 'etudiants/liste_etudiants_page.dart';

class GestionNiveauDetailPage extends StatefulWidget {
  final Groupe groupe;

  const GestionNiveauDetailPage({super.key, required this.groupe});

  @override
  State<GestionNiveauDetailPage> createState() => _GestionNiveauDetailPageState();
}

class _GestionNiveauDetailPageState extends State<GestionNiveauDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filiereNom = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _chargerNomFiliere();
  }

  Future<void> _chargerNomFiliere() async {
    try {
      final nom = await _firestoreService.getFiliereNomById(widget.groupe.filiereId);
      setState(() {
        _filiereNom = nom;
      });
    } catch (e) {
      setState(() {
        _filiereNom = 'Erreur de chargement';
      });
    }
  }

  void _ajouterEtudiant(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AjouterEtudiantDialog(
        groupe: widget.groupe,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Étudiant ajouté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _afficherListeEtudiants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeEtudiantsPage(groupe: widget.groupe),
      ),
    );
  }

  void _gestionEmploiTemps(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionEmploiTempsPage(groupe: widget.groupe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion - ${widget.groupe.nom}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header du groupe
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Groupe ${widget.groupe.nom}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Filière: $_filiereNom'), // ← Utiliser le nom chargé
                    Text('Niveau: ${widget.groupe.niveau}'),
                    const SizedBox(height: 8),
                    StreamBuilder<int>(
                      stream: _firestoreService.getNombreEtudiantsParGroupeStream(widget.groupe.id),
                      builder: (context, snapshot) {
                        final nombreEtudiants = snapshot.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$nombreEtudiants étudiants',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  title: 'Liste des Étudiants',
                  icon: Icons.list,
                  color: Colors.blue,
                  onTap: () => _afficherListeEtudiants(context),
                ),
                _buildActionCard(
                  title: 'Ajouter Étudiant',
                  icon: Icons.person_add,
                  color: Colors.green,
                  onTap: () => _ajouterEtudiant(context),
                ),
                _buildActionCard(
                  title: 'Emploi du Temps',
                  icon: Icons.schedule,
                  color: Colors.teal,
                  onTap: () => _gestionEmploiTemps(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
