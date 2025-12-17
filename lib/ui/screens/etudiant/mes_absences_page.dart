import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/absence.dart';
import '../../../../core/models/cours.dart';
import '../../../../core/models/etudiant.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';

class MesAbsencesContent extends StatefulWidget {
  const MesAbsencesContent({super.key});

  @override
  State<MesAbsencesContent> createState() => _MesAbsencesContentState();
}

class _MesAbsencesContentState extends State<MesAbsencesContent> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Absence> _absences = [];
  Map<String, Cours> _coursMap = {};
  Map<String, String> _enseignantNoms = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _filtreStatut = 'Tous';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final List<String> _filtresStatut = [
    'Tous',
    'non_justifie',
    'en_attente',
    'accepte',
    'refuse'
  ];

  @override
  void initState() {
    super.initState();
    _chargerAbsences();
  }

  Future<void> _chargerAbsences() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Etudiant) {
        setState(() {
          _errorMessage = 'Utilisateur non reconnu comme étudiant';
          _isLoading = false;
        });
        return;
      }

      final etudiantId = currentUser.id;
      await _chargerDonneesAbsences(etudiantId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des absences: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerDonneesAbsences(String etudiantId) async {
    try {
      final absencesStream = _firestoreService.getAbsencesParEtudiantStream(etudiantId);

      final subscription = absencesStream.listen((absencesList) {
        if (mounted) {
          setState(() {
            // Appliquer les filtres côté client
            _absences = _filtrerAbsences(absencesList);
            _isLoading = false;
          });
          _chargerDetailsCours(_absences);
        }
      });

      // Garder la subscription
      await subscription.asFuture();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Absence> _filtrerAbsences(List<Absence> absences) {
    // Appliquer tous les filtres côté client
    if (_filtreStatut != 'Tous') {
      absences = absences.where((a) => a.statutJustification == _filtreStatut).toList();
    }

    if (_dateDebut != null) {
      absences = absences.where((a) => !a.dateSeance.isBefore(_dateDebut!)).toList();
    }

    if (_dateFin != null) {
      final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
      absences = absences.where((a) => !a.dateSeance.isAfter(fin)).toList();
    }

    return absences;
  }

  Future<void> _chargerDetailsCours(List<Absence> absences) async {
    final coursIds = absences.map((a) => a.coursId).toSet();
    final enseignantIds = absences.map((a) => a.enseignantId).toSet();

    // Charger les noms des cours
    for (final coursId in coursIds) {
      try {
        final details = await _firestoreService.getCoursAvecDetails(coursId);
        _coursMap[coursId] = details['cours'] as Cours;
      } catch (e) {
        print('Erreur chargement cours $coursId: $e');
      }
    }

    // Charger les noms des enseignants
    for (final enseignantId in enseignantIds) {
      try {
        final nom = await _firestoreService.getEnseignantNomById(enseignantId);
        _enseignantNoms[enseignantId] = nom;
      } catch (e) {
        print('Erreur chargement enseignant $enseignantId: $e');
      }
    }

    setState(() {});
  }

  String _getNomCours(String coursId) {
    return _coursMap[coursId]?.nom ?? 'Chargement...';
  }

  String _getNomEnseignant(String enseignantId) {
    return _enseignantNoms[enseignantId] ?? 'Chargement...';
  }

  Widget _buildAbsenceCard(Absence absence) {
    final coursNom = _getNomCours(absence.coursId);
    final enseignantNom = _getNomEnseignant(absence.enseignantId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: absence.statutColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconStatut(absence.statutJustification),
            color: absence.statutColor,
            size: 20,
          ),
        ),
        title: Text(
          coursNom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enseignant: $enseignantNom'),
            Text('Date: ${_formaterDate(absence.dateSeance)}'),
            Text('Horaire: ${_formatTimeOfDay(absence.heureDebut)} - ${_formatTimeOfDay(absence.heureFin)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: absence.statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: absence.statutColor.withOpacity(0.3)),
              ),
              child: Text(
                absence.statutText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: absence.statutColor,
                ),
              ),
            ),
            if (absence.justificatif != null && absence.justificatif!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Justificatif: ${absence.justificatif}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (absence.motifRefus != null && absence.motifRefus!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motif refus: ${absence.motifRefus}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: absence.estJustifiable
            ? IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.blue),
          onPressed: () => _justifierAbsence(absence),
        )
            : null,
        onTap: () => _afficherDetailsAbsence(absence),
      ),
    );
  }

  IconData _getIconStatut(String statut) {
    switch (statut) {
      case 'non_justifie':
        return Icons.cancel;
      case 'en_attente':
        return Icons.access_time;
      case 'accepte':
        return Icons.check_circle;
      case 'refuse':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _formaterDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _justifierAbsence(Absence absence) {
    showDialog(
      context: context,
      builder: (context) => JustificationDialog(
        absence: absence,
        onSave: (justificatif, remarques) async {
          try {
            await _firestoreService.justifierAbsence(
              absenceId: absence.id,
              justificatif: justificatif,
              remarques: remarques,
            );
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Absence justifiée avec succès'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la justification: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  void _modifierJustification(Absence absence) {
    showDialog(
      context: context,
      builder: (context) => JustificationDialog(
        absence: absence,
        isModification: true,
        onSave: (justificatif, remarques) async {
          try {
            await _firestoreService.modifierJustification(
              absenceId: absence.id,
              justificatif: justificatif,
              remarques: remarques,
            );
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Justification modifiée avec succès'),
                backgroundColor: Colors.green,
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
      ),
    );
  }

  void _afficherDetailsAbsence(Absence absence) {
    final coursNom = _getNomCours(absence.coursId);
    final enseignantNom = _getNomEnseignant(absence.enseignantId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'absence'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Cours', coursNom),
              _buildDetailItem('Enseignant', enseignantNom),
              _buildDetailItem('Date', _formaterDate(absence.dateSeance)),
              _buildDetailItem('Horaire',
                  '${_formatTimeOfDay(absence.heureDebut)} - ${_formatTimeOfDay(absence.heureFin)}'),
              _buildDetailItem('Statut', absence.statutText),
              if (absence.justificatif != null && absence.justificatif!.isNotEmpty)
                _buildDetailItem('Justificatif', absence.justificatif!),
              if (absence.remarques != null && absence.remarques!.isNotEmpty)
                _buildDetailItem('Remarques', absence.remarques!),
              if (absence.motifRefus != null && absence.motifRefus!.isNotEmpty)
                _buildDetailItem('Motif du refus', absence.motifRefus!),
              if (absence.dateJustification != null)
                _buildDetailItem('Date justification',
                    _formaterDate(absence.dateJustification!)),
            ],
          ),
        ),
        actions: [
          if (absence.estJustifiable || absence.estEnAttente)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (absence.estJustifiable) {
                  _justifierAbsence(absence);
                } else {
                  _modifierJustification(absence);
                }
              },
              child: Text(absence.estJustifiable ? 'Justifier' : 'Modifier'),
            ),
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
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _afficherFiltres() async {
    await showDialog(
      context: context,
      builder: (context) => FiltresDialog(
        filtreStatut: _filtreStatut,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        onFiltresChanged: (statut, debut, fin) {
          setState(() {
            _filtreStatut = statut;
            _dateDebut = debut;
            _dateFin = fin;
          });
          _chargerAbsences();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreAbsences = _absences.length;
    final absencesJustifiables = _absences.where((a) => a.estJustifiable).length;
    final absencesEnAttente = _absences.where((a) => a.estEnAttente).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Absences'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _afficherFiltres,
            tooltip: 'Filtrer',
          ),
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
        ],
      ),
      body: Column(
        children: [
          // Header avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes absences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        '$nombreAbsences absence(s) trouvée(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicateurs rapides
                if (absencesJustifiables > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$absencesJustifiables à justifier',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Indicateur de filtre actif
          if (_filtreStatut != 'Tous' || _dateDebut != null || _dateFin != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTexteFiltreActif(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filtreStatut = 'Tous';
                        _dateDebut = null;
                        _dateFin = null;
                      });
                      _chargerAbsences();
                    },
                    child: Text(
                      'Effacer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
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
                    onPressed: _chargerAbsences,
                  ),
                ],
              ),
            ),
          ],

          // Liste des absences
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de vos absences...'),
                ],
              ),
            )
                : _absences.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune absence trouvée',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Vous n\'avez aucune absence pour le moment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _absences.length,
              itemBuilder: (context, index) {
                final absence = _absences[index];
                return _buildAbsenceCard(absence);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chargerAbsences,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _getTexteFiltreActif() {
    final parties = <String>[];

    if (_filtreStatut != 'Tous') {
      final statutText = _filtresStatut.firstWhere(
            (s) => s == _filtreStatut,
        orElse: () => _filtreStatut,
      );
      parties.add('Statut: $statutText');
    }

    if (_dateDebut != null) {
      parties.add('À partir du ${_formaterDate(_dateDebut!)}');
    }

    if (_dateFin != null) {
      parties.add('Jusqu\'au ${_formaterDate(_dateFin!)}');
    }

    return parties.join(' • ');
  }
}

// Dialog pour justifier une absence
class JustificationDialog extends StatefulWidget {
  final Absence absence;
  final bool isModification;
  final Function(String justificatif, String remarques) onSave;

  const JustificationDialog({
    super.key,
    required this.absence,
    this.isModification = false,
    required this.onSave,
  });

  @override
  State<JustificationDialog> createState() => _JustificationDialogState();
}

class _JustificationDialogState extends State<JustificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _justificatifController = TextEditingController();
  final _remarquesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isModification) {
      _justificatifController.text = widget.absence.justificatif ?? '';
      _remarquesController.text = widget.absence.remarques ?? '';
    }
  }

  @override
  void dispose() {
    _justificatifController.dispose();
    _remarquesController.dispose();
    super.dispose();
  }

  void _sauvegarder() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      widget.onSave(
        _justificatifController.text.trim(),
        _remarquesController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isModification ? 'Modifier la justification' : 'Justifier l\'absence'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations sur l'absence
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Absence du ${_formaterDate(widget.absence.dateSeance)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatTimeOfDay(widget.absence.heureDebut)} - ${_formatTimeOfDay(widget.absence.heureFin)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Justificatif
              TextFormField(
                controller: _justificatifController,
                decoration: const InputDecoration(
                  labelText: 'Justificatif *',
                  hintText: 'Ex: Maladie, Problème de transport, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un justificatif';
                  }
                  if (value.length < 10) {
                    return 'Le justificatif doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Remarques
              TextFormField(
                controller: _remarquesController,
                decoration: const InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  hintText: 'Informations complémentaires...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _sauvegarder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isModification ? 'Modifier' : 'Justifier'),
          ),
        ],
      ],
    );
  }

  String _formaterDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Dialog pour les filtres
class FiltresDialog extends StatefulWidget {
  final String filtreStatut;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final Function(String, DateTime?, DateTime?) onFiltresChanged;

  const FiltresDialog({
    super.key,
    required this.filtreStatut,
    required this.dateDebut,
    required this.dateFin,
    required this.onFiltresChanged,
  });

  @override
  State<FiltresDialog> createState() => _FiltresDialogState();
}

class _FiltresDialogState extends State<FiltresDialog> {
  late String _filtreStatut;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final List<String> _filtresStatut = [
    'Tous',
    'non_justifie',
    'en_attente',
    'accepte',
    'refuse'
  ];

  @override
  void initState() {
    super.initState();
    _filtreStatut = widget.filtreStatut;
    _dateDebut = widget.dateDebut;
    _dateFin = widget.dateFin;
  }

  Future<void> _selectDateDebut(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked;
      });
    }
  }

  Future<void> _selectDateFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateFin = picked;
      });
    }
  }

  void _appliquerFiltres() {
    widget.onFiltresChanged(_filtreStatut, _dateDebut, _dateFin);
    Navigator.pop(context);
  }

  void _reinitialiser() {
    setState(() {
      _filtreStatut = 'Tous';
      _dateDebut = null;
      _dateFin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer les absences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtre par statut
            DropdownButtonFormField<String>(
              value: _filtreStatut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              items: _filtresStatut.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(_getTexteStatut(statut)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _filtreStatut = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtre par date de début
            InkWell(
              onTap: () => _selectDateDebut(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'À partir du',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateDebut != null
                          ? _formaterDate(_dateDebut!)
                          : 'Sélectionner une date',
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filtre par date de fin
            InkWell(
              onTap: () => _selectDateFin(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Jusqu\'au',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateFin != null
                          ? _formaterDate(_dateFin!)
                          : 'Sélectionner une date',
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reinitialiser,
          child: const Text('Réinitialiser'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _appliquerFiltres,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  String _getTexteStatut(String statut) {
    switch (statut) {
      case 'Tous':
        return 'Tous les statuts';
      case 'non_justifie':
        return 'Non justifiées';
      case 'en_attente':
        return 'En attente';
      case 'accepte':
        return 'Justifiées';
      case 'refuse':
        return 'Refusées';
      default:
        return statut;
    }
  }

  String _formaterDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
