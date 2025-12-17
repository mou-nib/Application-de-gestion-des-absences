class Admin {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final DateTime dateCreation;

  Admin({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'dateCreation': dateCreation.toIso8601String(),
      'role': 'admin',
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      motDePasse: map['motDePasse'] ?? '',
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
    );
  }

  String get fullName => '$prenom $nom';

  Admin copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? motDePasse,
    DateTime? dateCreation,
  }) {
    return Admin(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Admin(id: $id, nom: $nom, prenom: $prenom, email: $email, dateCreation: $dateCreation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Admin && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}