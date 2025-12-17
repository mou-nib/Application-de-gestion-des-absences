import 'package:flutter/material.dart';
import '../../../../../core/models/etudiant.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/services/firestore_service.dart';
import 'modifier_etudiant_dialog.dart'; // Import ajouté

class ListeEtudiantsPage extends StatefulWidget {
  final Groupe groupe;

  const ListeEtudiantsPage({super.key, required this.groupe});

  @override
  State<ListeEtudiantsPage> createState() => _ListeEtudiantsPageState();
}

class _ListeEtudiantsPageState extends State<ListeEtudiantsPage> {
  late FirestoreService _firestoreService;
  List<Etudiant> _etudiants = [];
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, String> _filiereNoms = {};
  Map<String, String> _groupeNoms = {};

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final etudiants = await _firestoreService.getEtudiantsParGroupe(widget.groupe.id);
      await _chargerNomsFiliereEtGroupe(etudiants);
      setState(() {
        _etudiants = etudiants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des étudiants: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerNomsFiliereEtGroupe(List<Etudiant> etudiants) async {
    final filiereIds = etudiants.map((e) => e.filiereId).toSet();
    final groupeIds = etudiants.map((e) => e.groupeId).toSet();

    for (final filiereId in filiereIds) {
      final nom = await _firestoreService.getFiliereNomById(filiereId);
      _filiereNoms[filiereId] = nom;
    }

    for (final groupeId in groupeIds) {
      final nom = await _firestoreService.getGroupeNomById(groupeId);
      _groupeNoms[groupeId] = nom;
    }
  }

  String _getFiliereNom(String filiereId) {
    return _filiereNoms[filiereId] ?? 'Chargement...';
  }

  String _getGroupeNom(String groupeId) {
    return _groupeNoms[groupeId] ?? 'Chargement...';
  }

  void _modifierEtudiant(Etudiant etudiant) {
    showDialog(
      context: context,
      builder: (context) => ModifierEtudiantDialog(
        etudiant: etudiant,
        groupe: widget.groupe,
      ),
    ).then((result) {
      if (result == true) {
        // L'étudiant a été modifié avec succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Étudiant "${etudiant.prenom} ${etudiant.nom}" modifié avec succès'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        // Recharger la liste
        _chargerEtudiants();
      }
    });
  }

  void _supprimerEtudiant(Etudiant etudiant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'étudiant'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'étudiant "${etudiant.prenom} ${etudiant.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerEtudiant(etudiant.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Étudiant "${etudiant.prenom} ${etudiant.nom}" supprimé avec succès'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Recharger la liste
                await _chargerEtudiants();
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

  Widget _buildEtudiantCard(Etudiant etudiant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: etudiant.isActif ? Colors.green[50] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: etudiant.isActif ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        title: Text(
          '${etudiant.prenom} ${etudiant.nom}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: etudiant.isActif ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CNE: ${etudiant.cne}'),
            Text('CIN: ${etudiant.cin}'),
            Text('Email: ${etudiant.email}'),
            Text('Filière: ${_getFiliereNom(etudiant.filiereId)}'),
            Text('Groupe: ${_getGroupeNom(etudiant.groupeId)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: etudiant.isActif ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    etudiant.isActif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 10,
                      color: etudiant.isActif ? Colors.green[800] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    etudiant.telephone.isNotEmpty ? etudiant.telephone : 'Tél: Non renseigné',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[800],
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
              _modifierEtudiant(etudiant);
            } else if (value == 'supprimer') {
              _supprimerEtudiant(etudiant);
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
          _afficherDetailsEtudiant(context, etudiant);
        },
      ),
    );
  }

  void _afficherDetailsEtudiant(BuildContext context, Etudiant etudiant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'étudiant'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nom complet', '${etudiant.prenom} ${etudiant.nom}'),
              _buildDetailItem('CNE', etudiant.cne),
              _buildDetailItem('CIN', etudiant.cin),
              _buildDetailItem('Email', etudiant.email),
              _buildDetailItem('Filière', _getFiliereNom(etudiant.filiereId)),
              _buildDetailItem('Groupe', _getGroupeNom(etudiant.groupeId)),
              _buildDetailItem('Niveau', etudiant.niveau),
              _buildDetailItem('Téléphone', etudiant.telephone.isNotEmpty ? etudiant.telephone : 'Non renseigné'),
              _buildDetailItem('Date de naissance', '${etudiant.dateNaissance.day}/${etudiant.dateNaissance.month}/${etudiant.dateNaissance.year}'),
              _buildDetailItem('Lieu de naissance', etudiant.lieuNaissance),
              _buildDetailItem('Nationalité', etudiant.nationalite),
              _buildDetailItem('Adresse', etudiant.adresse.isNotEmpty ? etudiant.adresse : 'Non renseignée'),
              _buildDetailItem('Date d\'inscription', '${etudiant.dateInscription.day}/${etudiant.dateInscription.month}/${etudiant.dateInscription.year}'),
              _buildDetailItem('État', etudiant.isActif ? 'Actif' : 'Inactif'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Étudiants - ${widget.groupe.nom}'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerEtudiants,
            tooltip: 'Actualiser',
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
                Icon(Icons.school, color: Colors.blue[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liste des étudiants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '${_etudiants.length} étudiant(s) trouvé(s)',
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
                      _etudiants.where((e) => e.isActif).length.toString(),
                      'Actifs',
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      _etudiants.where((e) => !e.isActif).length.toString(),
                      'Inactifs',
                      Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gestion des états de chargement et d'erreur
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
                    onPressed: _chargerEtudiants,
                  ),
                ],
              ),
            ),
          ],

          // Liste des étudiants
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des étudiants...'),
                ],
              ),
            )
                : _etudiants.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun étudiant trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Ajoutez des étudiants pour les voir apparaître ici',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _etudiants.length,
              itemBuilder: (context, index) {
                final etudiant = _etudiants[index];
                return _buildEtudiantCard(etudiant);
              },
            ),
          ),
        ],
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
