class Etudiant {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String cin;
  final String cne;
  final String filiereId;
  final String groupeId;
  final String niveau;
  final String etat;
  final String motDePasse;
  final DateTime dateInscription;
  final String telephone;
  final String adresse;
  final DateTime dateNaissance;
  final String lieuNaissance;
  final String nationalite;

  Etudiant({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.cin,
    required this.cne,
    required this.filiereId,
    required this.groupeId,
    required this.niveau,
    required this.etat,
    required this.motDePasse,
    required this.dateInscription,
    required this.telephone,
    required this.adresse,
    required this.dateNaissance,
    required this.lieuNaissance,
    required this.nationalite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'cin': cin,
      'cne': cne,
      'filiereId': filiereId,
      'groupeId': groupeId,
      'niveau': niveau,
      'etat': etat,
      'motDePasse': motDePasse,
      'dateInscription': dateInscription.toIso8601String(),
      'telephone': telephone,
      'adresse': adresse,
      'dateNaissance': dateNaissance.toIso8601String(),
      'lieuNaissance': lieuNaissance,
      'nationalite': nationalite,
      'role': 'etudiant',
    };
  }

  factory Etudiant.fromMap(Map<String, dynamic> map) {
    return Etudiant(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      cin: map['cin'] ?? '',
      cne: map['cne'] ?? '',
      filiereId: map['filiereId'] ?? '',
      groupeId: map['groupeId'] ?? '',
      niveau: map['niveau'] ?? '',
      etat: map['etat'] ?? 'actif',
      motDePasse: map['motDePasse'] ?? '',
      dateInscription: map['dateInscription'] != null
          ? DateTime.parse(map['dateInscription'])
          : DateTime.now(),
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      dateNaissance: map['dateNaissance'] != null
          ? DateTime.parse(map['dateNaissance'])
          : DateTime.now(),
      lieuNaissance: map['lieuNaissance'] ?? '',
      nationalite: map['nationalite'] ?? 'Marocaine',
    );
  }

  String get fullName => '$prenom $nom';

  bool get isActif => etat == 'actif';

  Etudiant copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? cin,
    String? cne,
    String? filiereId,
    String? groupeId,
    String? niveau,
    String? etat,
    String? motDePasse,
    DateTime? dateInscription,
    String? telephone,
    String? adresse,
    DateTime? dateNaissance,
    String? lieuNaissance,
    String? nationalite,
  }) {
    return Etudiant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      cin: cin ?? this.cin,
      cne: cne ?? this.cne,
      filiereId: filiereId ?? this.filiereId,
      groupeId: groupeId ?? this.groupeId,
      niveau: niveau ?? this.niveau,
      etat: etat ?? this.etat,
      motDePasse: motDePasse ?? this.motDePasse,
      dateInscription: dateInscription ?? this.dateInscription,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      nationalite: nationalite ?? this.nationalite,
    );
  }

  @override
  String toString() {
    return 'Etudiant(id: $id, nom: $nom, prenom: $prenom, filiereId: $filiereId, groupeId: $groupeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Etudiant && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
