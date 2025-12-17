class Groupe {
  final String id;
  final String nom;
  final String filiereId;
  final String niveau;

  Groupe({
    required this.id,
    required this.nom,
    required this.filiereId,
    required this.niveau,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'filiereId': filiereId,
      'niveau': niveau,
    };
  }

  factory Groupe.fromMap(Map<String, dynamic> map) {
    return Groupe(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      filiereId: map['filiereId'] ?? '',
      niveau: map['niveau'] ?? '',
    );
  }

  Groupe copyWith({
    String? id,
    String? nom,
    String? filiereId,
    String? niveau,
  }) {
    return Groupe(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      filiereId: filiereId ?? this.filiereId,
      niveau: niveau ?? this.niveau,
    );
  }

  @override
  String toString() {
    return 'Groupe(id: $id, nom: $nom, filiereId: $filiereId, niveau: $niveau)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Groupe && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
