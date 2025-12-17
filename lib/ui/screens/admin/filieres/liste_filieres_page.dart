import 'package:flutter/material.dart';
import '../../../../../core/models/filiere.dart';
import '../../../../../core/services/firestore_service.dart';
import 'filiere_form_dialog.dart';
import '../groupes/liste_groupes_page.dart';

class ListeFilieresPage extends StatefulWidget {
  final String niveau;

  const ListeFilieresPage({super.key, required this.niveau});

  @override
  State<ListeFilieresPage> createState() => _ListeFilieresPageState();
}

class _ListeFilieresPageState extends State<ListeFilieresPage> {
  late FirestoreService _firestoreService;
  Stream<List<Map<String, dynamic>>>? _filieresStream;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _initializeStream();
  }

  void _initializeStream() {
    setState(() {
      _filieresStream = _firestoreService.getFilieresAvecNombreEtudiantsStream(widget.niveau);
      _errorMessage = null;
    });
  }

  void _ajouterFiliere() {
    showDialog(
      context: context,
      builder: (context) => FiliereFormDialog(
        onSave: (nouvelleFiliere) async {
          try {
            await _firestoreService.ajouterFiliere(nouvelleFiliere);
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Filière "${nouvelleFiliere.nom}" ajoutée avec succès'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Plus besoin de recharger manuellement, le Stream se met à jour automatiquement
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
        niveau: widget.niveau,
      ),
    );
  }

  void _modifierFiliere(Filiere filiere) {
    showDialog(
      context: context,
      builder: (context) => FiliereFormDialog(
        filiere: filiere,
        onSave: (filiereModifiee) async {
          try {
            await _firestoreService.modifierFiliere(filiereModifiee);
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Filière "${filiereModifiee.nom}" modifiée avec succès'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
            // Plus besoin de recharger manuellement
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
        niveau: widget.niveau,
      ),
    );
  }

  void _supprimerFiliere(Filiere filiere) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la filière'),
        content: Text('Êtes-vous sûr de vouloir supprimer la filière "${filiere.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.supprimerFiliere(filiere.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filière "${filiere.nom}" supprimée avec succès'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Plus besoin de recharger manuellement
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
        title: Text('Filières - ${widget.niveau}'),
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
                Icon(Icons.school, color: Colors.blue[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filières disponibles',
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
                  onPressed: _ajouterFiliere,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle Filière'),
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

          // Liste des filières avec StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getFilieresAvecDetailsStream(widget.niveau),
              builder: (context, snapshot) {
                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des filières...'),
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
                final filieresAvecEffectif = snapshot.data ?? [];

                if (filieresAvecEffectif.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune filière trouvée',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Cliquez sur "+" pour ajouter une filière',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filieresAvecEffectif.length,
                  itemBuilder: (context, index) {
                    final item = filieresAvecEffectif[index];
                    final filiere = item['filiere'] as Filiere;
                    final nombreEtudiants = item['nombreEtudiants'] as int;
                    final responsableNom = item['responsableNom'] as String;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.architecture, color: Colors.blue[700]),
                        ),
                        title: Text(
                          filiere.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(filiere.description),
                            const SizedBox(height: 4),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$nombreEtudiants étudiants',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      responsableNom,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'modifier') {
                              _modifierFiliere(filiere);
                            } else if (value == 'supprimer') {
                              _supprimerFiliere(filiere);
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
                          _ouvrirListeGroupes(context, filiere);
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

  void _ouvrirListeGroupes(BuildContext context, Filiere filiere) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeGroupesPage(filiere: filiere),
      ),
    );
  }
}