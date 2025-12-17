class Filiere {
  final String id;
  final String nom;
  final String niveau;
  final String description;
  final String responsableId;
  final DateTime dateCreation;

  Filiere({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.description,
    required this.responsableId,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'description': description,
      'responsableId': responsableId,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Filiere.fromMap(Map<String, dynamic> map) {
    return Filiere(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      niveau: map['niveau'] ?? '',
      description: map['description'] ?? '',
      responsableId: map['responsableId'] ?? '',
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
    );
  }

  Filiere copyWith({
    String? id,
    String? nom,
    String? niveau,
    String? description,
    String? responsableId,
    DateTime? dateCreation,
  }) {
    return Filiere(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      niveau: niveau ?? this.niveau,
      description: description ?? this.description,
      responsableId: responsableId ?? this.responsableId,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Filiere(id: $id, nom: $nom, niveau: $niveau)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Filiere && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}