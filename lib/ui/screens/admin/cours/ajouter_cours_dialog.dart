import 'package:flutter/material.dart';
import '../../../../../core/models/cours.dart';
import '../../../../../core/models/enseignant.dart';
import '../../../../../core/models/filiere.dart';
import '../../../../../core/services/firestore_service.dart';

class AjouterCoursDialog extends StatefulWidget {
  final Function(Cours)? onSave;
  final Cours? cours;

  const AjouterCoursDialog({super.key, this.onSave, this.cours});

  @override
  State<AjouterCoursDialog> createState() => _AjouterCoursDialogState();
}

class _AjouterCoursDialogState extends State<AjouterCoursDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dureeController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  List<Enseignant> _enseignants = [];
  List<Filiere> _filieres = [];
  String? _selectedEnseignantId;
  String? _selectedFiliereId;
  String _selectedNiveau = '1ère Année';
  bool _isLoading = false;

  final List<String> _niveaux = [
    '1ère Année',
    '2ème Année',
    '3ème Année',
    '4ème Année',
    '5ème Année'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cours != null) {
      _nomController.text = widget.cours!.nom;
      _descriptionController.text = widget.cours!.description;
      _dureeController.text = widget.cours!.dureeHeures.toString();
      _selectedEnseignantId = widget.cours!.enseignantId;
      _selectedFiliereId = widget.cours!.filiereId;
      _selectedNiveau = widget.cours!.niveau;
    }
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final enseignants = await _firestoreService.getTousLesEnseignants();
      final filieres = await _firestoreService.getFilieres();

      setState(() {
        _enseignants = enseignants.where((e) => e.isActif).toList();
        _filieres = filieres;

        if (_selectedEnseignantId == null && _enseignants.isNotEmpty) {
          _selectedEnseignantId = _enseignants.first.id;
        }
        if (_selectedFiliereId == null && _filieres.isNotEmpty) {
          _selectedFiliereId = _filieres.first.id;
        }
      });
    } catch (e) {
      print('Erreur chargement données: $e');
    }
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate() &&
        _selectedEnseignantId != null &&
        _selectedFiliereId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cours = Cours(
          id: widget.cours?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          nom: _nomController.text.trim(),
          enseignantId: _selectedEnseignantId!,
          filiereId: _selectedFiliereId!,
          niveau: _selectedNiveau,
          dureeHeures: int.tryParse(_dureeController.text) ?? 0,
          description: _descriptionController.text.trim(),
          dateCreation: widget.cours?.dateCreation ?? DateTime.now(),
        );

        if (widget.cours == null) {
          await _firestoreService.ajouterCours(cours);
        } else {
          await _firestoreService.modifierCours(cours);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sauvegarde: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _dureeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isModification = widget.cours != null;

    return AlertDialog(
      title: Text(isModification ? 'Modifier le cours' : 'Nouveau cours'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du cours *',
                  hintText: 'Ex: Algorithmique et Programmation',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du cours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description du cours...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Sélection de l'enseignant
              DropdownButtonFormField<String>(
                value: _selectedEnseignantId,
                decoration: const InputDecoration(
                  labelText: 'Enseignant *',
                  border: OutlineInputBorder(),
                ),
                items: _enseignants.map((enseignant) {
                  return DropdownMenuItem(
                    value: enseignant.id,
                    child: Text('${enseignant.prenom} ${enseignant.nom}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEnseignantId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un enseignant';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection de la filière
              DropdownButtonFormField<String>(
                value: _selectedFiliereId,
                decoration: const InputDecoration(
                  labelText: 'Filière *',
                  border: OutlineInputBorder(),
                ),
                items: _filieres.map((filiere) {
                  return DropdownMenuItem(
                    value: filiere.id,
                    child: Text(filiere.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFiliereId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une filière';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection du niveau
              DropdownButtonFormField<String>(
                value: _selectedNiveau,
                decoration: const InputDecoration(
                  labelText: 'Niveau *',
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
                    _selectedNiveau = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Durée en heures
              TextFormField(
                controller: _dureeController,
                decoration: const InputDecoration(
                  labelText: 'Durée (heures) *',
                  hintText: 'Ex: 45',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la durée';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _sauvegarder,
            style: ElevatedButton.styleFrom(
              backgroundColor: isModification ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isModification ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ],
    );
  }
}
