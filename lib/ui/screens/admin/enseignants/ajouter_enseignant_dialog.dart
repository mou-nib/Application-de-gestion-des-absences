import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../core/models/enseignant.dart';
import '../../../../../core/services/auth_service.dart';

class AjouterEnseignantDialog extends StatefulWidget {
  final Function(Enseignant)? onSave;

  const AjouterEnseignantDialog({super.key, this.onSave});

  @override
  State<AjouterEnseignantDialog> createState() => _AjouterEnseignantDialogState();
}

class _AjouterEnseignantDialogState extends State<AjouterEnseignantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();

  String _etat = 'actif';
  bool _isLoading = false;

  // Générer un mot de passe aléatoire
  String _genererMotDePasse() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      8,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final motDePasse = _genererMotDePasse();

        // Utiliser la nouvelle méthode qui crée dans Auth ET Firestore
        final enseignant = await authService.createEnseignant(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          motDePasse: motDePasse,
        );

        // Afficher le mot de passe généré (dans un vrai projet, l'envoyer par email)
        if (mounted) {
          Navigator.of(context).pop(true);

          // Montrer le mot de passe généré
          _showPasswordGeneratedDialog(motDePasse);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showPasswordGeneratedDialog(String motDePasse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enseignant créé avec succès'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('L\'enseignant a été créé avec succès.'),
            const SizedBox(height: 16),
            const Text(
              'Mot de passe généré:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                motDePasse,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notez ce mot de passe et communiquez-le à l\'enseignant.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Enseignant'),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter l\'enseignant'),
          ),
        ],
      ],
    );
  }
}
