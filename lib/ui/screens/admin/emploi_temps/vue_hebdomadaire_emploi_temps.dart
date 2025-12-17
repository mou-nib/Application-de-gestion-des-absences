import 'package:flutter/material.dart';
import '../../../../../core/models/groupe.dart';
import '../../../../../core/models/emploi_temps.dart';
import '../../../../../core/models/cours.dart';

class VueHebdomadaireEmploiTemps extends StatelessWidget {
  final Groupe groupe;
  final List<Map<String, dynamic>> emploisAvecDetails;
  final Function(EmploiTemps) onCreneauTap;

  const VueHebdomadaireEmploiTemps({
    super.key,
    required this.groupe,
    required this.emploisAvecDetails,
    required this.onCreneauTap,
  });

  @override
  Widget build(BuildContext context) {
    final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    final creneauxHoraires = _genererCreneauxHoraires();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // En-tête avec les jours
            _buildHeaderJours(jours),
            const SizedBox(height: 8),

            // Grille des créneaux
            _buildGrilleEmploiTemps(context, jours, creneauxHoraires),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderJours(List<String> jours) {
    return Row(
      children: [
        // Cellule vide pour l'heure
        Container(
          width: 80,
          height: 40,
          alignment: Alignment.center,
          child: const Text(
            'Heure',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...jours.map((jour) => Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getCouleurJour(jour).withOpacity(0.1),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              jour,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getCouleurJour(jour),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildGrilleEmploiTemps(BuildContext context, List<String> jours, List<TimeOfDay> creneauxHoraires) {
    return Column(
      children: creneauxHoraires.map((horaire) {
        return Row(
          children: [
            // Cellule heure
            Container(
              width: 80,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _formatTimeOfDay(horaire), // Utiliser la méthode de formatage sans context
                style: const TextStyle(fontSize: 12),
              ),
            ),
            // Cellules pour chaque jour
            ...jours.map((jour) => Expanded(
              child: _buildCelluleJour(context, jour, horaire),
            )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCelluleJour(BuildContext context, String jour, TimeOfDay horaire) {
    final creneauxDuJour = emploisAvecDetails.where((item) {
      final emploi = item['emploiTemps'] as EmploiTemps;
      return emploi.jour == jour &&
          _estDansCreneau(emploi, horaire);
    }).toList();

    if (creneauxDuJour.isEmpty) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
        ),
      );
    }

    final item = creneauxDuJour.first;
    final emploi = item['emploiTemps'] as EmploiTemps;
    final cours = item['cours'] as Cours;

    return GestureDetector(
      onTap: () => onCreneauTap(emploi),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _getCouleurJour(jour).withOpacity(0.2),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cours.nom,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              emploi.salle,
              style: const TextStyle(fontSize: 8),
            ),
            const Spacer(),
            Text(
              '${_formatTimeOfDay(emploi.heureDebut)}-${_formatTimeOfDay(emploi.heureFin)}', // Utiliser la méthode de formatage
              style: const TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  bool _estDansCreneau(EmploiTemps emploi, TimeOfDay horaire) {
    final heureDebut = emploi.heureDebut.hour * 60 + emploi.heureDebut.minute;
    final heureFin = emploi.heureFin.hour * 60 + emploi.heureFin.minute;
    final heureActuelle = horaire.hour * 60 + horaire.minute;

    return heureActuelle >= heureDebut && heureActuelle < heureFin;
  }

  List<TimeOfDay> _genererCreneauxHoraires() {
    final creneaux = <TimeOfDay>[];
    for (int heure = 8; heure <= 18; heure++) {
      creneaux.add(TimeOfDay(hour: heure, minute: 0));
    }
    return creneaux;
  }

  Color _getCouleurJour(String jour) {
    final couleurs = {
      'Lundi': Colors.blue,
      'Mardi': Colors.green,
      'Mercredi': Colors.orange,
      'Jeudi': Colors.purple,
      'Vendredi': Colors.red,
      'Samedi': Colors.brown,
    };
    return couleurs[jour] ?? Colors.grey;
  }

  // Méthode pour formater TimeOfDay sans utiliser .format(context)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}