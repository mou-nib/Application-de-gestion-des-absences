class Cours {
  final String id;
  final String nom;
  final String enseignantId;
  final String filiereId;
  final String niveau;
  final int dureeHeures;
  final String description;
  final DateTime dateCreation;

  Cours({
    required this.id,
    required this.nom,
    required this.enseignantId,
    required this.filiereId,
    required this.niveau,
    required this.dureeHeures,
    required this.description,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'enseignantId': enseignantId,
      'filiereId': filiereId,
      'niveau': niveau,
      'dureeHeures': dureeHeures,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Cours.fromMap(Map<String, dynamic> map) {
    return Cours(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      enseignantId: map['enseignantId'] ?? '',
      filiereId: map['filiereId'] ?? '',
      niveau: map['niveau'] ?? '',
      dureeHeures: map['dureeHeures'] ?? 0,
      description: map['description'] ?? '',
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
    );
  }

  Cours copyWith({
    String? id,
    String? nom,
    String? enseignantId,
    String? filiereId,
    String? niveau,
    int? dureeHeures,
    String? description,
    DateTime? dateCreation,
  }) {
    return Cours(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      enseignantId: enseignantId ?? this.enseignantId,
      filiereId: filiereId ?? this.filiereId,
      niveau: niveau ?? this.niveau,
      dureeHeures: dureeHeures ?? this.dureeHeures,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Cours(id: $id, nom: $nom, niveau: $niveau, duree: ${dureeHeures}h)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cours && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
