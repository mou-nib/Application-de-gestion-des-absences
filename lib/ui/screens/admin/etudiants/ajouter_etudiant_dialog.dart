import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../core/models/etudiant.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/services/auth_service.dart';

class AjouterEtudiantDialog extends StatefulWidget {
  final Groupe groupe;
  final Function(Etudiant)? onSave;

  const AjouterEtudiantDialog({
    super.key,
    required this.groupe,
    this.onSave,
  });

  @override
  State<AjouterEtudiantDialog> createState() => _AjouterEtudiantDialogState();
}

class _AjouterEtudiantDialogState extends State<AjouterEtudiantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _cinController = TextEditingController();
  final _cneController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController(text: 'Marocaine');
  DateTime _dateNaissance = DateTime.now().subtract(const Duration(days: 365 * 18));
  String _etat = 'actif';
  bool _isLoading = false;
  String _filiereNom = 'Chargement...';

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
        final etudiant = await authService.createEtudiant(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          motDePasse: motDePasse,
          cin: _cinController.text.trim(),
          cne: _cneController.text.trim(),
          filiereId: widget.groupe.filiereId,
          groupeId: widget.groupe.id,
          niveau: widget.groupe.niveau,
          telephone: _telephoneController.text.trim(),
          adresse: _adresseController.text.trim(),
          dateNaissance: _dateNaissance,
          lieuNaissance: _lieuNaissanceController.text.trim(),
          nationalite: _nationaliteController.text.trim(),
        );

        // Fermer le dialog et montrer le mot de passe
        if (mounted) {
          Navigator.of(context).pop(true);
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
        title: const Text('Étudiant créé avec succès'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('L\'étudiant a été créé avec succès.'),
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
              'Notez ce mot de passe et communiquez-le à l\'étudiant.',
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

  Future<void> _selectDateNaissance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'Sélectionnez la date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      fieldLabelText: 'Date de naissance',
      fieldHintText: 'JJ/MM/AAAA',
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() {
        _dateNaissance = picked;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _cinController.dispose();
    _cneController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Étudiant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations du groupe
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Groupe: ${widget.groupe.nom}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Filière: $_filiereNom'),
                      Text('Niveau: ${widget.groupe.niveau}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

              // CIN et CNE
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cinController,
                      decoration: const InputDecoration(
                        labelText: 'CIN *',
                        hintText: 'Ex: AB123456',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le CIN';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cneController,
                      decoration: const InputDecoration(
                        labelText: 'CNE *',
                        hintText: 'Ex: G123456789',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le CNE';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: +212 6 12 34 56 78',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Date de naissance
              InkWell(
                onTap: () => _selectDateNaissance(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance *',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dateNaissance.day}/${_dateNaissance.month}/${_dateNaissance.year}',
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lieu de naissance et Nationalité
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lieuNaissanceController,
                      decoration: const InputDecoration(
                        labelText: 'Lieu de naissance *',
                        hintText: 'Ex: Casablanca',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le lieu de naissance';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nationaliteController,
                      decoration: const InputDecoration(
                        labelText: 'Nationalité *',
                        hintText: 'Ex: Marocaine',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la nationalité';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Ex: 123 Rue Mohammed V, Casablanca',
                ),
                maxLines: 2,
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
            child: const Text('Ajouter l\'étudiant'),
          ),
        ],
      ],
    );
  }
}