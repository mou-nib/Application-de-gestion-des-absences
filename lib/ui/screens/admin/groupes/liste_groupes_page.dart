import 'package:flutter/material.dart';
import '../../../../../core/models/filiere.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/services/firestore_service.dart';
import '../gestion_niveau_detail.dart';
import 'groupe_form_dialog.dart';

class ListeGroupesPage extends StatefulWidget {
  final Filiere filiere;

  const ListeGroupesPage({super.key, required this.filiere});

  @override
  State<ListeGroupesPage> createState() => _ListeGroupesPageState();
}

class _ListeGroupesPageState extends State<ListeGroupesPage> {
  late FirestoreService _firestoreService;
  Stream<List<Map<String, dynamic>>>? _groupesStream;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _initializeStream();
  }

  void _initializeStream() {
    setState(() {
      _groupesStream = _firestoreService.getGroupesAvecNombreEtudiantsStream(widget.filiere.id);
      _errorMessage = null;
    });
  }

  void _ajouterGroupe() {
    showDialog(
      context: context,
      builder: (context) => GroupeFormDialog(
        onSave: (nouveauGroupe) async {
          try {
            await _firestoreService.ajouterGroupe(nouveauGroupe);
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Groupe "${nouveauGroupe.nom}" ajouté avec succès'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'ajout: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        filiere: widget.filiere,
      ),
    );
  }

  void _modifierGroupe(Groupe groupe) {
    showDialog(
      context: context,
      builder: (context) => GroupeFormDialog(
        groupe: groupe,
        onSave: (groupeModifie) async {
          try {
            await _firestoreService.modifierGroupe(groupeModifie);
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Groupe "${groupeModifie.nom}" modifié avec succès'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la modification: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        filiere: widget.filiere,
      ),
    );
  }

  void _supprimerGroupe(Groupe groupe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: Text('Êtes-vous sûr de vouloir supprimer le groupe "${groupe.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerGroupe(groupe.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Groupe "${groupe.nom}" supprimé avec succès'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groupes - ${widget.filiere.nom}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.blue[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Groupes disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        'Mise à jour automatique',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _ajouterGroupe,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Groupe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
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
                    onPressed: _initializeStream,
                  ),
                ],
              ),
            ),
          ],

          // Liste des groupes avec StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _groupesStream,
              builder: (context, snapshot) {
                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des groupes...'),
                      ],
                    ),
                  );
                }

                // Gestion des erreurs
                if (snapshot.hasError) {
                  return Center(
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
                          snapshot.error.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeStream,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                // Données disponibles
                final groupesAvecEffectif = snapshot.data ?? [];

                if (groupesAvecEffectif.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun groupe trouvé',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Cliquez sur "+" pour ajouter un groupe',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: groupesAvecEffectif.length,
                  itemBuilder: (context, index) {
                    final item = groupesAvecEffectif[index];
                    final groupe = item['groupe'] as Groupe;
                    final nombreEtudiants = item['nombreEtudiants'] as int;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.group, color: Colors.green[700]),
                        ),
                        title: Text(
                          groupe.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$nombreEtudiants étudiants'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'modifier') {
                              _modifierGroupe(groupe);
                            } else if (value == 'supprimer') {
                              _supprimerGroupe(groupe);
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
                          _ouvrirGestionDetaillee(context, groupe);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirGestionDetaillee(BuildContext context, Groupe groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionNiveauDetailPage(groupe: groupe),
      ),
    );
  }
}
