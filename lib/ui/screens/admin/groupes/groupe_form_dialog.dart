import 'package:flutter/material.dart';
import '../../../../../core/models/filiere.dart';
import '../../../../../core/models/groupe.dart';

class GroupeFormDialog extends StatefulWidget {
  final Groupe? groupe;
  final Function(Groupe) onSave;
  final Filiere filiere;

  const GroupeFormDialog({
    super.key,
    this.groupe,
    required this.onSave,
    required this.filiere,
  });

  @override
  State<GroupeFormDialog> createState() => _GroupeFormDialogState();
}

class _GroupeFormDialogState extends State<GroupeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.groupe != null) {
      _nomController.text = widget.groupe!.nom;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  void _sauvegarder() {
    if (_formKey.currentState!.validate()) {
      final groupe = Groupe(
        id: widget.groupe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        filiereId: widget.filiere.id,
        niveau: widget.filiere.niveau,
      );
      widget.onSave(groupe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isModification = widget.groupe != null;

    return AlertDialog(
      title: Text(isModification ? 'Modifier le groupe' : 'Nouveau groupe'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations de la filière
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filière: ${widget.filiere.nom}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Niveau: ${widget.filiere.niveau}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe *',
                  hintText: 'Ex: Groupe A',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du groupe';
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