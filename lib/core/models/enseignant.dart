class Enseignant {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String etat;
  final DateTime dateAjout;

  Enseignant({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.etat,
    required this.dateAjout,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'etat': etat,
      'dateAjout': dateAjout.toIso8601String(),
      'role': 'enseignant',
    };
  }

  factory Enseignant.fromMap(Map<String, dynamic> map) {
    return Enseignant(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      motDePasse: map['motDePasse'] ?? '',
      etat: map['etat'] ?? 'actif',
      dateAjout: map['dateAjout'] != null
          ? DateTime.parse(map['dateAjout'])
          : DateTime.now(),
    );
  }

  String get fullName => '$prenom $nom';

  bool get isActif => etat == 'actif';

  Enseignant copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? motDePasse,
    String? departement,
    String? etat,
    DateTime? dateAjout,
  }) {
    return Enseignant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      etat: etat ?? this.etat,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  @override
  String toString() {
    return 'Enseignant(id: $id, nom: $nom, prenom: $prenom, email: $email, etat: $etat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enseignant && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
