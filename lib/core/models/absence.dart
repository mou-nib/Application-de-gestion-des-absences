import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Absence {
  final String id;
  final String etudiantId;
  final String coursId;
  final String enseignantId;
  final String groupeId;
  final DateTime dateSeance;
  final String jour;
  final TimeOfDay heureDebut;
  final TimeOfDay heureFin;
  final bool estAbsent;
  final String? justificatif;
  final String? remarques;
  final DateTime dateCreation;
  final String statutJustification;
  final DateTime? dateJustification;
  final String? motifRefus;

  Absence({
    required this.id,
    required this.etudiantId,
    required this.coursId,
    required this.enseignantId,
    required this.groupeId,
    required this.dateSeance,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.estAbsent,
    this.justificatif,
    this.remarques,
    required this.dateCreation,
    this.statutJustification = 'non_justifie',
    this.dateJustification,
    this.motifRefus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'etudiantId': etudiantId,
      'coursId': coursId,
      'enseignantId': enseignantId,
      'groupeId': groupeId,
      'dateSeance': Timestamp.fromDate(dateSeance),
      'jour': jour,
      'heureDebut': '${heureDebut.hour.toString().padLeft(2, '0')}:${heureDebut.minute.toString().padLeft(2, '0')}',
      'heureFin': '${heureFin.hour.toString().padLeft(2, '0')}:${heureFin.minute.toString().padLeft(2, '0')}',
      'estAbsent': estAbsent,
      'justificatif': justificatif,
      'remarques': remarques,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'statutJustification': statutJustification,
      'dateJustification': dateJustification != null
          ? Timestamp.fromDate(dateJustification!)
          : null,
      'motifRefus': motifRefus,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    final heureDebutParts = (map['heureDebut'] as String).split(':');
    final heureFinParts = (map['heureFin'] as String).split(':');

    final dateSeance = (map['dateSeance'] as Timestamp).toDate();
    final dateCreation = (map['dateCreation'] as Timestamp).toDate();

    return Absence(
      id: map['id'] ?? '',
      etudiantId: map['etudiantId'] ?? '',
      coursId: map['coursId'] ?? '',
      enseignantId: map['enseignantId'] ?? '',
      groupeId: map['groupeId'] ?? '',
      dateSeance: dateSeance,
      jour: map['jour'] ?? '',
      heureDebut: TimeOfDay(
        hour: int.parse(heureDebutParts[0]),
        minute: int.parse(heureDebutParts[1]),
      ),
      heureFin: TimeOfDay(
        hour: int.parse(heureFinParts[0]),
        minute: int.parse(heureFinParts[1]),
      ),
      estAbsent: map['estAbsent'] ?? false,
      justificatif: map['justificatif'],
      remarques: map['remarques'],
      statutJustification: map['statutJustification'] ?? 'non_justifie',
      dateJustification: map['dateJustification'] != null
          ? (map['dateJustification'] as Timestamp).toDate()
          : null,
      motifRefus: map['motifRefus'],
      dateCreation: dateCreation,
    );
  }

  Absence copyWith({
    String? id,
    String? etudiantId,
    String? coursId,
    String? enseignantId,
    String? groupeId,
    DateTime? dateSeance,
    String? jour,
    TimeOfDay? heureDebut,
    TimeOfDay? heureFin,
    bool? estAbsent,
    String? justificatif,
    String? remarques,
    DateTime? dateCreation,
    String? statutJustification,
    DateTime? dateJustification,
    String? motifRefus,
  }) {
    return Absence(
      id: id ?? this.id,
      etudiantId: etudiantId ?? this.etudiantId,
      coursId: coursId ?? this.coursId,
      enseignantId: enseignantId ?? this.enseignantId,
      groupeId: groupeId ?? this.groupeId,
      dateSeance: dateSeance ?? this.dateSeance,
      jour: jour ?? this.jour,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      estAbsent: estAbsent ?? this.estAbsent,
      justificatif: justificatif ?? this.justificatif,
      remarques: remarques ?? this.remarques,
      dateCreation: dateCreation ?? this.dateCreation,
      statutJustification: statutJustification ?? this.statutJustification,
      dateJustification: dateJustification ?? this.dateJustification,
      motifRefus: motifRefus ?? this.motifRefus,
    );
  }

  Absence validerJustification({String? remarques}) {
    return copyWith(
      statutJustification: 'accepte',
      dateJustification: DateTime.now(),
      remarques: remarques ?? this.remarques,
      motifRefus: null,
    );
  }

  Absence refuserJustification({required String motifRefus, String? remarques}) {
    return copyWith(
      statutJustification: 'refuse',
      dateJustification: DateTime.now(),
      motifRefus: motifRefus,
      remarques: remarques ?? this.remarques,
    );
  }

  bool get peutEtreValidee => statutJustification == 'en_attente';
  bool get peutEtreRefusee => statutJustification == 'en_attente';

  @override
  String toString() {
    return 'Absence(id: $id, etudiantId: $etudiantId, coursId: $coursId, date: $dateSeance, absent: $estAbsent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Absence && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  bool get estJustifiable => estAbsent && statutJustification == 'non_justifie';
  bool get estEnAttente => statutJustification == 'en_attente';
  bool get estJustifiee => statutJustification == 'accepte';
  bool get estRefusee => statutJustification == 'refuse';

  String get statutText {
    switch (statutJustification) {
      case 'non_justifie':
        return 'Non justifiée';
      case 'en_attente':
        return 'En attente';
      case 'accepte':
        return 'Justifiée';
      case 'refuse':
        return 'Refusée';
      default:
        return 'Inconnu';
    }
  }

  Color get statutColor {
    switch (statutJustification) {
      case 'non_justifie':
        return Colors.red;
      case 'en_attente':
        return Colors.orange;
      case 'accepte':
        return Colors.green;
      case 'refuse':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
