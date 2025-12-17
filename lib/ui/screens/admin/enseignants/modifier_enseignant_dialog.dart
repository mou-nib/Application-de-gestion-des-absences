import 'package:flutter/material.dart';
import '../../../../../core/models/enseignant.dart';
import '../../../../../core/services/firestore_service.dart';

class ModifierEnseignantDialog extends StatefulWidget {
  final Enseignant enseignant;
  final Function(Enseignant)? onSave;

  const ModifierEnseignantDialog({
    super.key,
    required this.enseignant,
    this.onSave,
  });

  @override
  State<ModifierEnseignantDialog> createState() => _ModifierEnseignantDialogState();
}

class _ModifierEnseignantDialogState extends State<ModifierEnseignantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _modulesController = TextEditingController();

  String _etat = 'actif';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données de l'enseignant
    _nomController.text = widget.enseignant.nom;
    _prenomController.text = widget.enseignant.prenom;
    _emailController.text = widget.enseignant.email;
    _etat = widget.enseignant.etat;
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Convertir les modules en liste
        final modules = _modulesController.text
            .split(',')
            .map((module) => module.trim())
            .where((module) => module.isNotEmpty)
            .toList();

        final enseignantModifie = widget.enseignant.copyWith(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          etat: _etat,
        );

        // Sauvegarder dans Firestore
        final firestoreService = FirestoreService();
        await firestoreService.modifierEnseignant(enseignantModifie);

        // Fermer le dialog
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
              content: Text('Erreur lors de la modification: $e'),
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
    _prenomController.dispose();
    _emailController.dispose();
    _modulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'Enseignant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom et Prénom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        hintText: 'Ex: BENALI',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        hintText: 'Ex: Ahmed',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le prénom';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Ex: ahmed.benali@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'email';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // État
              DropdownButtonFormField<String>(
                value: _etat,
                decoration: const InputDecoration(
                  labelText: 'État *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'actif',
                    child: Text('Actif'),
                  ),
                  DropdownMenuItem(
                    value: 'inactif',
                    child: Text('Inactif'),
                  ),
                ],
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _etat = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner l\'état';
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ],
    );
  }
}