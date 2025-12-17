import 'package:flutter/material.dart';
import '../../../../../core/models/emploi_temps.dart';
import '../../../../../core/models/cours.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/services/firestore_service.dart';

class AjouterEmploiTempsDialog extends StatefulWidget {
  final Groupe groupe;
  final EmploiTemps? emploiTemps;
  final Function(EmploiTemps)? onSave;

  const AjouterEmploiTempsDialog({
    super.key,
    required this.groupe,
    this.emploiTemps,
    this.onSave,
  });

  @override
  State<AjouterEmploiTempsDialog> createState() => _AjouterEmploiTempsDialogState();
}

class _AjouterEmploiTempsDialogState extends State<AjouterEmploiTempsDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  List<Cours> _cours = [];
  String? _selectedCoursId;
  String? _selectedJour;
  TimeOfDay _heureDebut = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 9, minute: 0);
  final _salleController = TextEditingController();
  bool _isLoading = false;
  bool _verificationConflit = false;

  final List<String> _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.emploiTemps != null) {
      _selectedCoursId = widget.emploiTemps!.coursId;
      _selectedJour = widget.emploiTemps!.jour;
      _heureDebut = widget.emploiTemps!.heureDebut;
      _heureFin = widget.emploiTemps!.heureFin;
      _salleController.text = widget.emploiTemps!.salle;
    } else {
      _selectedJour = _jours.first;
    }
    _chargerCours();
  }

  Future<void> _chargerCours() async {
    try {
      final cours = await _firestoreService.getCoursParNiveau(widget.groupe.niveau);
      setState(() {
        _cours = cours;
        if (_selectedCoursId == null && _cours.isNotEmpty) {
          _selectedCoursId = _cours.first.id;
        }
      });
    } catch (e) {
      print('Erreur chargement cours: $e');
    }
  }

  Future<bool> _verifierConflits() async {
    if (_selectedJour == null) return false;

    try {
      final conflit = await _firestoreService.verifierConflitEmploiTemps(
        groupeId: widget.groupe.id,
        jour: _selectedJour!,
        heureDebut: _heureDebut,
        heureFin: _heureFin,
        emploiTempsId: widget.emploiTemps?.id,
      );
      return conflit;
    } catch (e) {
      print('Erreur vérification conflits: $e');
      return false;
    }
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate() &&
        _selectedCoursId != null &&
        _selectedJour != null) {

      setState(() {
        _isLoading = true;
        _verificationConflit = true;
      });

      // Vérifier les conflits
      final conflit = await _verifierConflits();

      if (conflit) {
        setState(() {
          _isLoading = false;
          _verificationConflit = false;
        });

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conflit détecté'),
            content: const Text('Ce créneau entre en conflit avec un autre cours. Veuillez choisir un autre horaire.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      try {
        final emploiTemps = EmploiTemps(
          id: widget.emploiTemps?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          groupeId: widget.groupe.id,
          coursId: _selectedCoursId!,
          jour: _selectedJour!,
          heureDebut: _heureDebut,
          heureFin: _heureFin,
          salle: _salleController.text.trim(),
          dateCreation: widget.emploiTemps?.dateCreation ?? DateTime.now(),
        );

        if (widget.emploiTemps == null) {
          await _firestoreService.ajouterEmploiTemps(emploiTemps);
        } else {
          await _firestoreService.modifierEmploiTemps(emploiTemps);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _verificationConflit = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sauvegarde: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectHeureDebut(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _heureDebut,
    );
    if (picked != null) {
      setState(() {
        _heureDebut = picked;
        // Ajuster l'heure de fin automatiquement
        if (_heureFin.hour < picked.hour ||
            (_heureFin.hour == picked.hour && _heureFin.minute <= picked.minute)) {
          _heureFin = TimeOfDay(
            hour: picked.hour + 1,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _selectHeureFin(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _heureFin,
    );
    if (picked != null) {
      setState(() {
        _heureFin = picked;
      });
    }
  }

  @override
  void dispose() {
    _salleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isModification = widget.emploiTemps != null;

    return AlertDialog(
      title: Text(isModification ? 'Modifier le créneau' : 'Nouveau créneau'),
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
                      Text('Niveau: ${widget.groupe.niveau}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sélection du cours
              DropdownButtonFormField<String>(
                value: _selectedCoursId,
                decoration: const InputDecoration(
                  labelText: 'Cours *',
                  border: OutlineInputBorder(),
                ),
                items: _cours.map((cours) {
                  return DropdownMenuItem(
                    value: cours.id,
                    child: Text(cours.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCoursId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un cours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection du jour
              DropdownButtonFormField<String>(
                value: _selectedJour,
                decoration: const InputDecoration(
                  labelText: 'Jour *',
                  border: OutlineInputBorder(),
                ),
                items: _jours.map((jour) {
                  return DropdownMenuItem(
                    value: jour,
                    child: Text(jour),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedJour = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un jour';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Heure de début et de fin
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectHeureDebut(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure début *',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_heureDebut.format(context)),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectHeureFin(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure fin *',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_heureFin.format(context)),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Salle
              TextFormField(
                controller: _salleController,
                decoration: const InputDecoration(
                  labelText: 'Salle *',
                  hintText: 'Ex: Salle 101',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la salle';
                  }
                  return null;
                },
              ),

              if (_verificationConflit) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                    SizedBox(width: 8),
                    Text('Vérification des conflits...'),
                  ],
                ),
              ],
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
