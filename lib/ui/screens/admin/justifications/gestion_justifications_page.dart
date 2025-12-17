import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/absence.dart';
import '../../../../../core/models/etudiant.dart';
import '../../../../../core/models/cours.dart';
import '../../../../../core/services/firestore_service.dart';

class GestionJustificationsPageContent extends StatefulWidget {
  const GestionJustificationsPageContent({super.key});

  @override
  State<GestionJustificationsPageContent> createState() => _GestionJustificationsPageContentState();
}

class _GestionJustificationsPageContentState extends State<GestionJustificationsPageContent> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Absence> _absencesEnAttente = [];
  Map<String, Map<String, dynamic>> _detailsAbsences = {};
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _absencesSubscription;

  @override
  void initState() {
    super.initState();
    _initialiserStream();
  }

  @override
  void dispose() {
    _absencesSubscription?.cancel();
    super.dispose();
  }

  void _initialiserStream() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final absencesStream = _firestoreService.getAbsencesEnAttenteStream();

      _absencesSubscription = absencesStream.listen(
            (absencesList) {
          if (mounted) {
            setState(() {
              _absencesEnAttente = absencesList;
              _isLoading = false;
            });
            _chargerDetailsAbsences(absencesList);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erreur lors du chargement: $error';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur d\'initialisation: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _chargerDetailsAbsences(List<Absence> absences) async {
    for (final absence in absences) {
      try {
        final details = await _firestoreService.getAbsenceAvecDetails(absence.id);
        if (mounted) {
          setState(() {
            _detailsAbsences[absence.id] = details;
          });
        }
      } catch (e) {
        print('Erreur chargement détails absence ${absence.id}: $e');
      }
    }
  }

  Future<void> _validerJustification(Absence absence) async {
    try {
      await _firestoreService.validerJustification(absenceId: absence.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Justification validée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _refuserJustification(Absence absence) async {
    final motifController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la justification'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Veuillez indiquer le motif du refus:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif du refus *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Justificatif insuffisant, hors délai...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un motif';
                  }
                  if (value.length < 5) {
                    return 'Le motif doit contenir au moins 5 caractères';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _firestoreService.refuserJustification(
                    absenceId: absence.id,
                    motifRefus: motifController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Justification refusée avec succès'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors du refus: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _afficherDetailsAbsence(Absence absence) {
    final details = _detailsAbsences[absence.id];
    final etudiant = details?['etudiant'] as Etudiant?;
    final cours = details?['cours'] as Cours?;
    final enseignantNom = details?['enseignantNom'] as String?;
    final filiereNom = details?['filiereNom'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'absence'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Étudiant', etudiant?.fullName ?? 'N/A'),
              _buildDetailItem('CNE', etudiant?.cne ?? 'N/A'),
              _buildDetailItem('Cours', cours?.nom ?? 'N/A'),
              _buildDetailItem('Enseignant', enseignantNom ?? 'N/A'),
              _buildDetailItem('Filière', filiereNom ?? 'N/A'),
              _buildDetailItem('Date', '${absence.dateSeance.day}/${absence.dateSeance.month}/${absence.dateSeance.year}'),
              _buildDetailItem('Horaire', '${_formatTimeOfDay(absence.heureDebut)} - ${_formatTimeOfDay(absence.heureFin)}'),
              _buildDetailItem('Justificatif', absence.justificatif ?? 'Aucun justificatif'),
              if (absence.remarques != null && absence.remarques!.isNotEmpty)
                _buildDetailItem('Remarques', absence.remarques!),
            ],
          ),
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

  Widget _buildAbsenceCard(Absence absence) {
    final details = _detailsAbsences[absence.id];
    final etudiant = details?['etudiant'] as Etudiant?;
    final cours = details?['cours'] as Cours?;
    final enseignantNom = details?['enseignantNom'] as String?;
    final filiereNom = details?['filiereNom'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations de base
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etudiant?.fullName ?? 'Étudiant inconnu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'CNE: ${etudiant?.cne ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'En attente',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations du cours
            Text(
              cours?.nom ?? 'Cours inconnu',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('Enseignant: ${enseignantNom ?? 'N/A'}'),
            Text('Filière: ${filiereNom ?? 'N/A'}'),

            const SizedBox(height: 12),

            // Date et horaire
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${absence.dateSeance.day}/${absence.dateSeance.month}/${absence.dateSeance.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_formatTimeOfDay(absence.heureDebut)} - ${_formatTimeOfDay(absence.heureFin)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Justificatif
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Justificatif:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    absence.justificatif ?? 'Aucun justificatif fourni',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            if (absence.remarques != null && absence.remarques!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remarques:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      absence.remarques!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _refuserJustification(absence),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerJustification(absence),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Valider'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _afficherDetailsAbsence(absence),
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  tooltip: 'Plus de détails',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _rechargerDonnees() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _detailsAbsences.clear();
    });
    _initialiserStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Justifications'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        actions: [
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.purple[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Justifications en attente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      Text(
                        '${_absencesEnAttente.length} demande(s) en attente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                    onPressed: _rechargerDonnees,
                  ),
                ],
              ),
            ),
          ],

          // Liste des justifications
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des justifications...'),
                ],
              ),
            )
                : _absencesEnAttente.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Aucune justification en attente',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Toutes les justifications ont été traitées',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _absencesEnAttente.length,
              itemBuilder: (context, index) {
                final absence = _absencesEnAttente[index];
                return _buildAbsenceCard(absence);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _rechargerDonnees,
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Actualiser',
      ),
    );
  }
}