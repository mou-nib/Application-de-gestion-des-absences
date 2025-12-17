import 'package:flutter/material.dart';
import '../../../../../core/models/filiere.dart';
import '../../../../../core/models/enseignant.dart';
import '../../../../../core/services/firestore_service.dart';

class FiliereFormDialog extends StatefulWidget {
  final Filiere? filiere;
  final Function(Filiere) onSave;
  final String niveau;

  const FiliereFormDialog({
    super.key,
    this.filiere,
    required this.onSave,
    required this.niveau,
  });

  @override
  State<FiliereFormDialog> createState() => _FiliereFormDialogState();
}

class _FiliereFormDialogState extends State<FiliereFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Enseignant> _enseignants = [];
  String? _selectedResponsableId;
  bool _isLoadingEnseignants = true;

  @override
  void initState() {
    super.initState();
    if (widget.filiere != null) {
      _nomController.text = widget.filiere!.nom;
      _descriptionController.text = widget.filiere!.description;
      _selectedResponsableId = widget.filiere!.responsableId;
    }
    _chargerEnseignants();
  }

  Future<void> _chargerEnseignants() async {
    try {
      final enseignants = await _firestoreService.getTousLesEnseignants();
      setState(() {
        _enseignants = enseignants
            .where((enseignant) => enseignant.isActif) // Seulement les enseignants actifs
            .toList();
        _isLoadingEnseignants = false;

        // Si pas de responsable sélectionné et qu'il y a des enseignants, sélectionner le premier
        if (_selectedResponsableId == null && _enseignants.isNotEmpty) {
          _selectedResponsableId = _enseignants.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingEnseignants = false;
      });
      print('Erreur chargement enseignants: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _sauvegarder() {
    if (_formKey.currentState!.validate() && _selectedResponsableId != null) {
      final filiere = Filiere(
        id: widget.filiere?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        niveau: widget.niveau,
        description: _descriptionController.text.trim(),
        responsableId: _selectedResponsableId!,
        dateCreation: widget.filiere?.dateCreation ?? DateTime.now(),
      );
      widget.onSave(filiere);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isModification = widget.filiere != null;

    return AlertDialog(
      title: Text(isModification ? 'Modifier la filière' : 'Nouvelle filière'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la filière *',
                  hintText: 'Ex: Génie Informatique',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de la filière';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Ex: Informatique et systèmes d\'information',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection du responsable
              _isLoadingEnseignants
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                value: _selectedResponsableId,
                decoration: const InputDecoration(
                  labelText: 'Responsable *',
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
                    _selectedResponsableId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un responsable';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _sauvegarder,
          child: Text(isModification ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}