import 'package:flutter/material.dart';
import '../../../../../core/models/enseignant.dart';
import '../../../../../core/services/firestore_service.dart';
import 'ajouter_enseignant_dialog.dart';
import 'modifier_enseignant_dialog.dart';

class ListeEnseignantsPage extends StatefulWidget {
  const ListeEnseignantsPage({super.key});

  @override
  State<ListeEnseignantsPage> createState() => _ListeEnseignantsPageState();
}

class _ListeEnseignantsPageState extends State<ListeEnseignantsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Enseignant> _enseignants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtreEtat = 'Tous';

  @override
  void initState() {
    super.initState();
    _chargerEnseignants();
  }

  Future<void> _chargerEnseignants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final enseignants = await _firestoreService.getTousLesEnseignants();
      setState(() {
        _enseignants = enseignants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des enseignants: $e';
        _isLoading = false;
      });
    }
  }

  List<Enseignant> _getEnseignantsFiltres() {
    if (_filtreEtat == 'Tous') {
      return _enseignants;
    }
    return _enseignants
        .where((enseignant) => enseignant.etat == _filtreEtat)
        .toList();
  }

  void _ajouterEnseignant() {
    showDialog(
      context: context,
      builder: (context) => const AjouterEnseignantDialog(),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enseignant ajouté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _chargerEnseignants();
      }
    });
  }

  void _modifierEnseignant(Enseignant enseignant) {
    showDialog(
      context: context,
      builder: (context) => ModifierEnseignantDialog(
        enseignant: enseignant,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enseignant "${enseignant.prenom} ${enseignant.nom}" modifié avec succès'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        _chargerEnseignants();
      }
    });
  }

  void _supprimerEnseignant(Enseignant enseignant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enseignant'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'enseignant "${enseignant.prenom} ${enseignant.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerEnseignant(enseignant.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enseignant "${enseignant.prenom} ${enseignant.nom}" supprimé avec succès'),
                    backgroundColor: Colors.red,
                  ),
                );
                await _chargerEnseignants();
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

  Widget _buildEnseignantCard(Enseignant enseignant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enseignant.isActif ? Colors.blue[50] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: enseignant.isActif ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        title: Text(
          '${enseignant.prenom} ${enseignant.nom}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enseignant.isActif ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${enseignant.email}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: enseignant.isActif ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    enseignant.isActif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 10,
                      color: enseignant.isActif ? Colors.green[800] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'modifier') {
              _modifierEnseignant(enseignant);
            } else if (value == 'supprimer') {
              _supprimerEnseignant(enseignant);
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
          _afficherDetailsEnseignant(enseignant);
        },
      ),
    );
  }

  void _afficherDetailsEnseignant(Enseignant enseignant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'enseignant'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nom complet', '${enseignant.prenom} ${enseignant.nom}'),
              _buildDetailItem('Email', enseignant.email),
              _buildDetailItem('Date d\'ajout',
                  '${enseignant.dateAjout.day}/${enseignant.dateAjout.month}/${enseignant.dateAjout.year}'),
              _buildDetailItem('État', enseignant.isActif ? 'Actif' : 'Inactif'),
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
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enseignantsFiltres = _getEnseignantsFiltres();
    final nombreActifs = _enseignants.where((e) => e.isActif).length;
    final nombreInactifs = _enseignants.where((e) => !e.isActif).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Enseignants'),
        backgroundColor: Colors.blue[800],
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
                Icon(Icons.school, color: Colors.blue[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liste des enseignants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '${enseignantsFiltres.length} enseignant(s) trouvé(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Statistiques rapides
                Row(
                  children: [
                    _buildStatItem(
                      nombreActifs.toString(),
                      'Actifs',
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      nombreInactifs.toString(),
                      'Inactifs',
                      Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtre simple
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownButtonFormField<String>(
                value: _filtreEtat,
                decoration: const InputDecoration(
                  labelText: 'Filtrer par état',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Tous',
                    child: Text('Tous les enseignants'),
                  ),
                  DropdownMenuItem(
                    value: 'actif',
                    child: Text('Actifs seulement'),
                  ),
                  DropdownMenuItem(
                    value: 'inactif',
                    child: Text('Inactifs seulement'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _filtreEtat = value!;
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
                    onPressed: _chargerEnseignants,
                  ),
                ],
              ),
            ),
          ],

          // Liste des enseignants
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des enseignants...'),
                ],
              ),
            )
                : enseignantsFiltres.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun enseignant trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Ajoutez des enseignants pour les voir apparaître ici',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: enseignantsFiltres.length,
              itemBuilder: (context, index) {
                final enseignant = enseignantsFiltres[index];
                return _buildEnseignantCard(enseignant);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEnseignant,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}
