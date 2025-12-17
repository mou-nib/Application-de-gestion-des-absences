import 'package:flutter/material.dart';

class EmploiTemps {
  final String id;
  final String groupeId;
  final String coursId;
  final String jour;
  final TimeOfDay heureDebut;
  final TimeOfDay heureFin;
  final String salle;
  final DateTime dateCreation;

  EmploiTemps({
    required this.id,
    required this.groupeId,
    required this.coursId,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.salle,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupeId': groupeId,
      'coursId': coursId,
      'jour': jour,
      'heureDebut': '${heureDebut.hour.toString().padLeft(2, '0')}:${heureDebut.minute.toString().padLeft(2, '0')}',
      'heureFin': '${heureFin.hour.toString().padLeft(2, '0')}:${heureFin.minute.toString().padLeft(2, '0')}',
      'salle': salle,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory EmploiTemps.fromMap(Map<String, dynamic> map) {
    final heureDebutParts = (map['heureDebut'] as String).split(':');
    final heureFinParts = (map['heureFin'] as String).split(':');

    return EmploiTemps(
      id: map['id'] ?? '',
      groupeId: map['groupeId'] ?? '',
      coursId: map['coursId'] ?? '',
      jour: map['jour'] ?? '',
      heureDebut: TimeOfDay(
        hour: int.parse(heureDebutParts[0]),
        minute: int.parse(heureDebutParts[1]),
      ),
      heureFin: TimeOfDay(
        hour: int.parse(heureFinParts[0]),
        minute: int.parse(heureFinParts[1]),
      ),
      salle: map['salle'] ?? '',
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
    );
  }

  bool chevaucheAvec(EmploiTemps autre) {
    if (jour != autre.jour) return false;

    final debut1 = heureDebut.hour * 60 + heureDebut.minute;
    final fin1 = heureFin.hour * 60 + heureFin.minute;
    final debut2 = autre.heureDebut.hour * 60 + autre.heureDebut.minute;
    final fin2 = autre.heureFin.hour * 60 + autre.heureFin.minute;

    return (debut1 < fin2 && fin1 > debut2);
  }

  int get dureeMinutes {
    final debut = heureDebut.hour * 60 + heureDebut.minute;
    final fin = heureFin.hour * 60 + heureFin.minute;
    return fin - debut;
  }

  String get horaireFormate {
    final debutHour = heureDebut.hour.toString().padLeft(2, '0');
    final debutMinute = heureDebut.minute.toString().padLeft(2, '0');
    final finHour = heureFin.hour.toString().padLeft(2, '0');
    final finMinute = heureFin.minute.toString().padLeft(2, '0');
    return '$debutHour:$debutMinute - $finHour:$finMinute';
  }

  EmploiTemps copyWith({
    String? id,
    String? groupeId,
    String? coursId,
    String? jour,
    TimeOfDay? heureDebut,
    TimeOfDay? heureFin,
    String? salle,
    DateTime? dateCreation,
  }) {
    return EmploiTemps(
      id: id ?? this.id,
      groupeId: groupeId ?? this.groupeId,
      coursId: coursId ?? this.coursId,
      jour: jour ?? this.jour,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      salle: salle ?? this.salle,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'EmploiTemps(id: $id, groupeId: $groupeId, coursId: $coursId, jour: $jour, $horaireFormate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmploiTemps && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
