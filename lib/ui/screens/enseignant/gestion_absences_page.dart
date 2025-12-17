import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/cours.dart';
import '../../../../core/models/etudiant.dart';
import '../../../../core/models/absence.dart';
import '../../../../core/models/enseignant.dart';
import '../../../../core/models/emploi_temps.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/auth_service.dart';

class GestionAbsencesPageContent extends StatefulWidget {
  const GestionAbsencesPageContent({super.key});

  @override
  State<GestionAbsencesPageContent> createState() => _GestionAbsencesPageContentState();
}

class _GestionAbsencesPageContentState extends State<GestionAbsencesPageContent> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Cours> _mesCours = [];
  List<EmploiTemps> _creneauxDuJour = [];
  EmploiTemps? _creneauSelectionne;
  List<Etudiant> _etudiantsDuGroupe = [];
  Map<String, bool> _absencesMap = {};
  Map<String, String> _justificatifsMap = {};
  DateTime _dateSelectionnee = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _absencesDejaMarquees = false; // Nouveau flag pour vérifier si les absences sont déjà marquées

  @override
  void initState() {
    super.initState();
    _chargerDonneesSeanceActuelle();
  }

  Future<void> _chargerDonneesSeanceActuelle() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _absencesDejaMarquees = false; // Réinitialiser le flag
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Enseignant) {
        setState(() {
          _errorMessage = 'Utilisateur non reconnu comme enseignant';
          _isLoading = false;
        });
        return;
      }

      final enseignantId = currentUser.id;

      // Charger les cours de l'enseignant
      _mesCours = await _firestoreService.getCoursParEnseignant(enseignantId);

      if (_mesCours.isNotEmpty) {
        await _chargerCreneauxDuJour();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerCreneauxDuJour() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Enseignant) return;

      // Pour chaque cours, charger les emplois du temps d'aujourd'hui
      final tousLesCreneaux = <EmploiTemps>[];
      final aujourdhui = _getNomJour(_dateSelectionnee.weekday);

      for (final cours in _mesCours) {
        final emplois = await _firestoreService.getEmploiTempsParCours(cours.id);
        final creneauxAujourdhui = emplois.where((emploi) => emploi.jour == aujourdhui).toList();
        tousLesCreneaux.addAll(creneauxAujourdhui);
      }

      setState(() {
        _creneauxDuJour = tousLesCreneaux;
        if (_creneauxDuJour.isNotEmpty) {
          _creneauSelectionne = _creneauxDuJour.first;
          _chargerEtudiantsEtAbsences();
        } else {
          _etudiantsDuGroupe = [];
          _absencesMap = {};
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des créneaux: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerEtudiantsEtAbsences() async {
    if (_creneauSelectionne == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Charger les étudiants du groupe
      _etudiantsDuGroupe = await _firestoreService.getEtudiantsParGroupe(_creneauSelectionne!.groupeId);

      // Vérifier si les absences ont déjà été marquées pour cette séance
      final absencesExistantes = await _firestoreService.getAbsencesParCoursEtDate(
          _creneauSelectionne!.coursId,
          _dateSelectionnee
      );

      if (absencesExistantes.isNotEmpty) {
        // Les absences sont déjà marquées
        setState(() {
          _absencesDejaMarquees = true;
          _absencesMap = {};
          _justificatifsMap = {};
          _isLoading = false;
        });
        return;
      }

      // Initialiser la map des absences (tous présents par défaut)
      _absencesMap = {};
      _justificatifsMap = {};

      for (final etudiant in _etudiantsDuGroupe) {
        _absencesMap[etudiant.id] = false;
        _justificatifsMap[etudiant.id] = '';
      }

      setState(() {
        _absencesDejaMarquees = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des étudiants: $e';
        _isLoading = false;
      });
    }
  }

  // Vérifier si la séance est en cours
  bool _seanceEstEnCours(EmploiTemps creneau) {
    final maintenant = DateTime.now();
    final heureActuelle = TimeOfDay.fromDateTime(maintenant);

    final debutMinutes = creneau.heureDebut.hour * 60 + creneau.heureDebut.minute;
    final finMinutes = creneau.heureFin.hour * 60 + creneau.heureFin.minute;
    final actuelMinutes = heureActuelle.hour * 60 + heureActuelle.minute;

    return actuelMinutes >= debutMinutes && actuelMinutes <= finMinutes;
  }

  // Vérifier si la séance est passée
  bool _seanceEstPassee(EmploiTemps creneau) {
    final maintenant = DateTime.now();
    final heureActuelle = TimeOfDay.fromDateTime(maintenant);

    final finMinutes = creneau.heureFin.hour * 60 + creneau.heureFin.minute;
    final actuelMinutes = heureActuelle.hour * 60 + heureActuelle.minute;

    return actuelMinutes > finMinutes;
  }

  // Obtenir le statut de la séance
  String _getStatutSeance(EmploiTemps creneau) {
    if (_seanceEstEnCours(creneau)) return 'en_cours';
    if (_seanceEstPassee(creneau)) return 'passee';
    return 'future';
  }

  String _getNomJour(int weekday) {
    final jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return jours[weekday];
  }

  String _getNomCours(String coursId) {
    try {
      final cours = _mesCours.firstWhere((c) => c.id == coursId);
      return cours.nom;
    } catch (e) {
      return 'Cours inconnu';
    }
  }

  String _formaterDate(DateTime date) {
    final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final mois = ['janv', 'fév', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];

    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _sauvegarderAbsences() async {
    if (_creneauSelectionne == null) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();

      if (currentUser is! Enseignant) {
        throw Exception('Utilisateur non reconnu comme enseignant');
      }

      final absences = <Absence>[];

      for (final etudiant in _etudiantsDuGroupe) {
        final estAbsent = _absencesMap[etudiant.id] ?? false;

        // CRÉER UNE ABSENCE SEULEMENT SI L'ÉTUDIANT EST ABSENT
        if (estAbsent) {
          final absenceId = '${etudiant.id}_${_creneauSelectionne!.coursId}_${_dateSelectionnee.millisecondsSinceEpoch}';

          final absence = Absence(
            id: absenceId,
            etudiantId: etudiant.id,
            coursId: _creneauSelectionne!.coursId,
            enseignantId: currentUser.id,
            groupeId: _creneauSelectionne!.groupeId,
            dateSeance: _dateSelectionnee,
            jour: _creneauSelectionne!.jour,
            heureDebut: _creneauSelectionne!.heureDebut,
            heureFin: _creneauSelectionne!.heureFin,
            estAbsent: true,
            justificatif: null,
            remarques: null,
            dateCreation: DateTime.now(),
            statutJustification: 'non_justifie',
          );

          absences.add(absence);
        }
      }

      if (absences.isNotEmpty) {
        await _firestoreService.marquerAbsencesBatch(absences);
      }

      setState(() {
        _isSaving = false;
        _absencesDejaMarquees = true; // Marquer que les absences sont maintenant sauvegardées
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${absences.length} absence(s) marquée(s) avec succès'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildEtudiantCard(Etudiant etudiant) {
    final estAbsent = _absencesMap[etudiant.id] ?? false;
    final seanceEnCours = _creneauSelectionne != null && _seanceEstEnCours(_creneauSelectionne!);

    // Si les absences sont déjà marquées, désactiver les switches
    final estModifiable = !_absencesDejaMarquees && seanceEnCours && !_isSaving;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: estAbsent ? Colors.red[50] : Colors.green[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estAbsent ? Colors.red[100] : Colors.green[100],
          child: Text(
            '${etudiant.prenom[0]}${etudiant.nom[0]}'.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: estAbsent ? Colors.red[800] : Colors.green[800],
            ),
          ),
        ),
        title: Text(
          '${etudiant.prenom} ${etudiant.nom}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: estAbsent ? Colors.red[800] : Colors.green[800],
          ),
        ),
        subtitle: Text('CNE: ${etudiant.cne}'),
        trailing: Switch(
          value: !estAbsent,
          onChanged: estModifiable ? (value) {
            setState(() {
              _absencesMap[etudiant.id] = !value;
            });
          } : null,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
      ),
    );
  }

  int _getNombreAbsents() {
    return _absencesMap.values.where((estAbsent) => estAbsent).length;
  }

  // Méthodes pour l'affichage du statut
  Color _getCouleurStatut(EmploiTemps creneau) {
    switch (_getStatutSeance(creneau)) {
      case 'en_cours':
        return Colors.green[50]!;
      case 'passee':
        return Colors.orange[50]!;
      case 'future':
        return Colors.blue[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getCouleurIconeStatut(EmploiTemps creneau) {
    switch (_getStatutSeance(creneau)) {
      case 'en_cours':
        return Colors.green;
      case 'passee':
        return Colors.orange;
      case 'future':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadgeStatut(EmploiTemps creneau) {
    final statut = _getStatutSeance(creneau);
    Color couleur;
    String texte;

    switch (statut) {
      case 'en_cours':
        couleur = Colors.green;
        texte = 'En cours';
        break;
      case 'passee':
        couleur = Colors.orange;
        texte = 'Terminée';
        break;
      case 'future':
        couleur = Colors.blue;
        texte = 'À venir';
        break;
      default:
        couleur = Colors.grey;
        texte = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: couleur,
        ),
      ),
    );
  }

  Widget _buildMessageStatut(EmploiTemps creneau) {
    final statut = _getStatutSeance(creneau);

    // Si les absences sont déjà marquées, afficher un message spécifique
    if (_absencesDejaMarquees) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.blue[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Absences déjà marquées pour cette séance',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    switch (statut) {
      case 'en_cours':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Séance en cours - Vous pouvez marquer les absences',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'passee':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Séance terminée - Le marquage des absences n\'est plus disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'future':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Séance à venir - Le marquage des absences sera disponible pendant la séance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildMessageAbsencesDejaMarquees() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.blue[300]),
          const SizedBox(height: 16),
          Text(
            'Absences déjà marquées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les absences pour cette séance ont déjà été enregistrées.\nVous ne pouvez plus les modifier.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSeanceTerminee() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_filled, size: 80, color: Colors.orange[300]),
          const SizedBox(height: 16),
          Text(
            'Séance terminée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le marquage des absences n\'est plus disponible\npour cette séance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAucunCreneau() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun créneau aujourd\'hui',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAucunEtudiant() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun étudiant dans ce groupe',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemSimple(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreAbsents = _getNombreAbsents();
    final nombreTotal = _etudiantsDuGroupe.length;
    final seanceEnCours = _creneauSelectionne != null && _seanceEstEnCours(_creneauSelectionne!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Absences'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
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
          // Header avec informations de la séance
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Date de la séance (lecture seule)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de la séance',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formaterDate(_dateSelectionnee),
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Créneau horaire (lecture seule)
                  if (_creneauxDuJour.isNotEmpty && _creneauSelectionne != null)
                    Column(
                      children: [
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Créneau horaire',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: _getCouleurStatut(_creneauSelectionne!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getNomCours(_creneauSelectionne!.coursId)),
                                    Text(
                                      '${_formatTimeOfDay(_creneauSelectionne!.heureDebut)} - ${_formatTimeOfDay(_creneauSelectionne!.heureFin)} • ${_creneauSelectionne!.salle}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildBadgeStatut(_creneauSelectionne!),
                                  ],
                                ),
                              ),
                              Icon(Icons.schedule, size: 20, color: _getCouleurIconeStatut(_creneauSelectionne!)),
                            ],
                          ),
                        ),

                        // Message d'information selon le statut
                        const SizedBox(height: 8),
                        _buildMessageStatut(_creneauSelectionne!),
                      ],
                    )
                  else
                    const Text(
                      'Aucun créneau programmé pour aujourd\'hui',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),

          // Statistiques (seulement si séance en cours et absences pas encore marquées)
          if (seanceEnCours &&
              _creneauSelectionne != null &&
              _etudiantsDuGroupe.isNotEmpty &&
              !_absencesDejaMarquees)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildStatItemSimple('Total', nombreTotal.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatItemSimple('Présents', (nombreTotal - nombreAbsents).toString(), Colors.green),
                  const SizedBox(width: 8),
                  _buildStatItemSimple('Absents', nombreAbsents.toString(), Colors.red),
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
                    onPressed: _chargerDonneesSeanceActuelle,
                  ),
                ],
              ),
            ),
          ],

          // Liste des étudiants ou message d'absences déjà marquées
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des étudiants...'),
                ],
              ),
            )
                : _creneauSelectionne == null
                ? _buildMessageAucunCreneau()
                : _absencesDejaMarquees
                ? _buildMessageAbsencesDejaMarquees()
                : !_seanceEstEnCours(_creneauSelectionne!)
                ? _buildMessageSeanceTerminee()
                : _etudiantsDuGroupe.isEmpty
                ? _buildMessageAucunEtudiant()
                : ListView.builder(
              itemCount: _etudiantsDuGroupe.length,
              itemBuilder: (context, index) {
                final etudiant = _etudiantsDuGroupe[index];
                return _buildEtudiantCard(etudiant);
              },
            ),
          ),

          // Bouton de sauvegarde (seulement si séance en cours et absences pas encore marquées)
          if (_creneauSelectionne != null &&
              _etudiantsDuGroupe.isNotEmpty &&
              _seanceEstEnCours(_creneauSelectionne!) &&
              !_absencesDejaMarquees)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _sauvegarderAbsences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Sauvegarde...' : 'Sauvegarder les absences',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
