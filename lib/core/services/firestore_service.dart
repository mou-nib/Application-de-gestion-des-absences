import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/absence.dart';
import '../models/cours.dart';
import '../models/emploi_temps.dart';
import '../models/enseignant.dart';
import '../models/filiere.dart';
import '../models/groupe.dart';
import '../models/etudiant.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get filieresCollection =>
      _firestore.collection('filieres');

  CollectionReference get groupesCollection => _firestore.collection('groupes');

  CollectionReference get etudiantsCollection =>
      _firestore.collection('etudiants');

  CollectionReference get enseignantsCollection =>
      _firestore.collection('enseignants');

  CollectionReference get coursCollection => _firestore.collection('cours');

  CollectionReference get emploiTempsCollection => _firestore.collection('emploi_temps');

  CollectionReference get absencesCollection => _firestore.collection('absences');


  Future<Map<String, dynamic>> getStatistiquesAdmin() async {
    try {
      final etudiantsQuery = await etudiantsCollection.get();
      final nombreEtudiants = etudiantsQuery.docs.length;

      final enseignantsQuery = await enseignantsCollection.get();
      final nombreEnseignants = enseignantsQuery.docs.length;

      final coursQuery = await coursCollection.get();
      final nombreCours = coursQuery.docs.length;

      final debutMois = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final finMois = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

      final absencesQuery = await absencesCollection
          .where('dateSeance', isGreaterThanOrEqualTo: Timestamp.fromDate(debutMois))
          .where('dateSeance', isLessThanOrEqualTo: Timestamp.fromDate(finMois))
          .get();
      final nombreAbsencesMois = absencesQuery.docs.length;

      return {
        'etudiants': nombreEtudiants,
        'enseignants': nombreEnseignants,
        'cours': nombreCours,
        'absences_mois': nombreAbsencesMois,
      };
    } catch (e) {
      print('Erreur getStatistiquesAdmin: $e');
      return {
        'etudiants': 0,
        'enseignants': 0,
        'cours': 0,
        'absences_mois': 0,
      };
    }
  }




  Future<List<Cours>> getCoursParEnseignant(String enseignantId) async {
    try {
      final querySnapshot = await coursCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();
      return querySnapshot.docs
          .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours par enseignant: $e');
    }
  }

  Stream<List<Cours>> getCoursParEnseignantStream(String enseignantId) {
    return coursCollection
        .where('enseignantId', isEqualTo: enseignantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<EmploiTemps>> getEmploiTempsParEnseignant(String enseignantId) async {
    try {
      final cours = await getCoursParEnseignant(enseignantId);
      final coursIds = cours.map((c) => c.id).toList();

      if (coursIds.isEmpty) return [];

      final querySnapshot = await emploiTempsCollection
          .where('coursId', whereIn: coursIds)
          .get();

      return querySnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'emploi du temps par enseignant: $e');
    }
  }

  Stream<List<EmploiTemps>> getEmploiTempsParEnseignantStream(String enseignantId) {
    return coursCollection
        .where('enseignantId', isEqualTo: enseignantId)
        .snapshots()
        .asyncMap((coursSnapshot) async {
      final coursIds = coursSnapshot.docs.map((doc) => doc.id).toList();
      if (coursIds.isEmpty) return [];

      final emploiSnapshot = await emploiTempsCollection
          .where('coursId', whereIn: coursIds)
          .get();

      return emploiSnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }




  Stream<List<Absence>> getAbsencesEnAttenteStream() {
    try {
      return absencesCollection
          .where('statutJustification', isEqualTo: 'en_attente')
          .snapshots()
          .map((snapshot) {
        final absences = snapshot.docs
            .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        absences.sort((a, b) => b.dateSeance.compareTo(a.dateSeance));

        return absences;
      });
    } catch (e) {
      print('Erreur getAbsencesEnAttenteStream: $e');
      return Stream.value([]);
    }
  }

  Future<void> validerJustification({
    required String absenceId,
    String? remarques,
  }) async {
    try {
      await absencesCollection.doc(absenceId).update({
        'statutJustification': 'accepte',
        'dateJustification': Timestamp.fromDate(DateTime.now()),
        'remarques': remarques,
        'motifRefus': null,
      });
    } catch (e) {
      throw Exception('Erreur lors de la validation de la justification: $e');
    }
  }

  Future<void> refuserJustification({
    required String absenceId,
    required String motifRefus,
    String? remarques,
  }) async {
    try {
      await absencesCollection.doc(absenceId).update({
        'statutJustification': 'refuse',
        'dateJustification': Timestamp.fromDate(DateTime.now()),
        'motifRefus': motifRefus,
        'remarques': remarques,
      });
    } catch (e) {
      throw Exception('Erreur lors du refus de la justification: $e');
    }
  }

  Future<Map<String, dynamic>> getAbsenceAvecDetails(String absenceId) async {
    try {
      final absenceDoc = await absencesCollection.doc(absenceId).get();
      if (!absenceDoc.exists) {
        throw Exception('Absence non trouvée');
      }

      final absence = Absence.fromMap(absenceDoc.data() as Map<String, dynamic>);

      final etudiantDoc = await etudiantsCollection.doc(absence.etudiantId).get();
      final etudiant = etudiantDoc.exists
          ? Etudiant.fromMap(etudiantDoc.data() as Map<String, dynamic>)
          : null;

      final coursDetails = await getCoursAvecDetails(absence.coursId);

      final enseignantNom = await getEnseignantNomById(absence.enseignantId);

      return {
        'absence': absence,
        'etudiant': etudiant,
        'cours': coursDetails['cours'],
        'enseignantNom': enseignantNom,
        'filiereNom': coursDetails['filiereNom'],
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails de l\'absence: $e');
    }
  }



  // ============ CRUD pour Absences ============

  Stream<List<Absence>> getAbsencesParEtudiantStream(
      String etudiantId, {
        String? filtreStatut,
        DateTime? dateDebut,
        DateTime? dateFin,
      }) {
    try {
      Query query = absencesCollection.where('etudiantId', isEqualTo: etudiantId);

      return query.snapshots().map((snapshot) {
        List<Absence> absences = snapshot.docs
            .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return _appliquerFiltresEtTri(absences, filtreStatut, dateDebut, dateFin);
      });
    } catch (e) {
      print('Erreur getAbsencesParEtudiantStream: $e');
      return Stream.value([]);
    }
  }

  List<Absence> _appliquerFiltresEtTri(
      List<Absence> absences,
      String? filtreStatut,
      DateTime? dateDebut,
      DateTime? dateFin,
      ) {
    if (filtreStatut != null && filtreStatut != 'Tous') {
      absences = absences.where((absence) => absence.statutJustification == filtreStatut).toList();
    }

    if (dateDebut != null) {
      absences = absences.where((absence) =>
      !absence.dateSeance.isBefore(dateDebut)).toList();
    }

    if (dateFin != null) {
      final finJour = DateTime(dateFin.year, dateFin.month, dateFin.day, 23, 59, 59);
      absences = absences.where((absence) =>
      !absence.dateSeance.isAfter(finJour)).toList();
    }

    absences.sort((a, b) => b.dateSeance.compareTo(a.dateSeance));

    return absences;
  }

  Future<void> justifierAbsence({
    required String absenceId,
    required String justificatif,
    required String remarques,
  }) async {
    try {
      await absencesCollection.doc(absenceId).update({
        'justificatif': justificatif,
        'remarques': remarques,
        'statutJustification': 'en_attente',
        'dateJustification': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de la justification de l\'absence: $e');
    }
  }

  Future<void> modifierJustification({
    required String absenceId,
    required String justificatif,
    required String remarques,
  }) async {
    try {
      await absencesCollection.doc(absenceId).update({
        'justificatif': justificatif,
        'remarques': remarques,
        'statutJustification': 'en_attente',
        'dateJustification': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de la modification de la justification: $e');
    }
  }

  Future<Map<String, int>> getStatistiquesAbsences(String etudiantId) async {
    try {
      final querySnapshot = await absencesCollection
          .where('etudiantId', isEqualTo: etudiantId)
          .get();

      final absences = querySnapshot.docs
          .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final total = absences.length;
      final nonJustifiees = absences.where((a) => a.statutJustification == 'non_justifie').length;
      final enAttente = absences.where((a) => a.statutJustification == 'en_attente').length;
      final justifiees = absences.where((a) => a.statutJustification == 'accepte').length;
      final refusees = absences.where((a) => a.statutJustification == 'refuse').length;

      return {
        'total': total,
        'non_justifiees': nonJustifiees,
        'en_attente': enAttente,
        'justifiees': justifiees,
        'refusees': refusees,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  Future<void> marquerAbsence(Absence absence) async {
    try {
      await absencesCollection.doc(absence.id).set(absence.toMap());
    } catch (e) {
      throw Exception('Erreur lors du marquage de l\'absence: $e');
    }
  }

  Future<void> marquerAbsencesBatch(List<Absence> absences) async {
    try {
      final batch = _firestore.batch();

      for (final absence in absences) {
        final docRef = absencesCollection.doc(absence.id);
        batch.set(docRef, absence.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du marquage des absences: $e');
    }
  }


  Future<List<Absence>> getAbsencesParCoursEtDate(String coursId, DateTime date) async {
    try {
      final querySnapshot = await absencesCollection
          .where('coursId', isEqualTo: coursId)
          .get();

      final debutJour = DateTime(date.year, date.month, date.day);
      final finJour = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return querySnapshot.docs
          .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
          .where((absence) {
        final dateAbsence = absence.dateSeance;
        return dateAbsence.isAfter(debutJour.subtract(const Duration(seconds: 1))) &&
            dateAbsence.isBefore(finJour.add(const Duration(seconds: 1)));
      })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des absences: $e');
    }
  }

  Future<List<Absence>> getAbsencesParEtudiant(String etudiantId) async {
    try {
      final querySnapshot = await absencesCollection
          .where('etudiantId', isEqualTo: etudiantId)
          .orderBy('dateSeance', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des absences de l\'étudiant: $e');
    }
  }

  Future<List<Absence>> getAbsencesParGroupeEtDate(String groupeId, DateTime date) async {
    try {
      final debutJour = DateTime(date.year, date.month, date.day);
      final finJour = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await absencesCollection
          .where('groupeId', isEqualTo: groupeId)
          .where('dateSeance', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
          .where('dateSeance', isLessThanOrEqualTo: Timestamp.fromDate(finJour))
          .get();

      return querySnapshot.docs
          .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des absences du groupe: $e');
    }
  }

  Stream<List<Absence>> getAbsencesParCoursEtDateStream(String coursId, DateTime date) {
    final debutJour = DateTime(date.year, date.month, date.day);
    final finJour = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return absencesCollection
        .where('coursId', isEqualTo: coursId)
        .where('dateSeance', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .where('dateSeance', isLessThanOrEqualTo: Timestamp.fromDate(finJour))
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<bool> verifierAbsenceExistante({
    required String etudiantId,
    required String coursId,
    required DateTime dateSeance,
  }) async {
    try {
      final debutJour = DateTime(dateSeance.year, dateSeance.month, dateSeance.day);
      final finJour = DateTime(dateSeance.year, dateSeance.month, dateSeance.day, 23, 59, 59);

      final querySnapshot = await absencesCollection
          .where('etudiantId', isEqualTo: etudiantId)
          .where('coursId', isEqualTo: coursId)
          .where('dateSeance', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
          .where('dateSeance', isLessThanOrEqualTo: Timestamp.fromDate(finJour))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'absence: $e');
    }
  }

  Future<void> modifierAbsence(Absence absence) async {
    try {
      await absencesCollection.doc(absence.id).update(absence.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'absence: $e');
    }
  }

  Future<void> supprimerAbsence(String absenceId) async {
    try {
      await absencesCollection.doc(absenceId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'absence: $e');
    }
  }

  Future<List<EmploiTemps>> getEmploiTempsParCours(String coursId) async {
    try {
      final querySnapshot = await emploiTempsCollection
          .where('coursId', isEqualTo: coursId)
          .get();
      return querySnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'emploi du temps par cours: $e');
    }
  }

  Stream<List<EmploiTemps>> getEmploiTempsParCoursStream(String coursId) {
    return emploiTempsCollection
        .where('coursId', isEqualTo: coursId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }
  // ============ CRUD pour Filieres ============

  Stream<List<Map<String, dynamic>>> getFilieresAvecNombreEtudiantsStream(String niveau) {
    return filieresCollection
        .where('niveau', isEqualTo: niveau)
        .snapshots()
        .asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final filiere = Filiere.fromMap(doc.data() as Map<String, dynamic>);
        final nombreEtudiants = await getNombreEtudiantsParFiliere(filiere.id);

        result.add({
          'filiere': filiere,
          'nombreEtudiants': nombreEtudiants,
        });
      }

      return result;
    });
  }

  Future<void> ajouterFiliere(Filiere filiere) async {
    try {
      await filieresCollection.doc(filiere.id).set(filiere.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la filière: $e');
    }
  }

  Future<String> getFiliereNomById(String filiereId) async {
    try {
      final doc = await filieresCollection.doc(filiereId).get();
      if (doc.exists) {
        final filiere = Filiere.fromMap(doc.data() as Map<String, dynamic>);
        return filiere.nom;
      }
      return 'Filière inconnue';
    } catch (e) {
      return 'Erreur de chargement';
    }
  }

  Future<List<Filiere>> getFilieres() async {
    try {
      final querySnapshot = await filieresCollection.get();
      return querySnapshot.docs
          .map((doc) => Filiere.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des filières: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFilieresAvecNombreEtudiants(String niveau) async {
    try {
      final filieres = await getFilieresParNiveau(niveau);
      final result = <Map<String, dynamic>>[];

      for (final filiere in filieres) {
        final nombreEtudiants = await getNombreEtudiantsParFiliere(filiere.id);
        result.add({
          'filiere': filiere,
          'nombreEtudiants': nombreEtudiants,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors du chargement des filières avec effectif: $e');
    }
  }

  Future<List<Filiere>> getFilieresParNiveau(String niveau) async {
    try {
      final querySnapshot = await filieresCollection
          .where('niveau', isEqualTo: niveau)
          .get();
      return querySnapshot.docs
          .map((doc) => Filiere.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des filières par niveau: $e');
    }
  }

  Future<void> modifierFiliere(Filiere filiere) async {
    try {
      await filieresCollection.doc(filiere.id).update(filiere.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification de la filière: $e');
    }
  }

  Future<void> supprimerFiliere(String filiereId) async {
    try {
      await filieresCollection.doc(filiereId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la filière: $e');
    }
  }

  Stream<List<Filiere>> getFilieresStream() {
    return filieresCollection.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Filiere.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Filiere>> getFilieresParNiveauStream(String niveau) {
    return filieresCollection
        .where('niveau', isEqualTo: niveau)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Filiere.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }



  // ============ CRUD pour Groupes ============

  Future<void> ajouterGroupe(Groupe groupe) async {
    try {
      await groupesCollection.doc(groupe.id).set(groupe.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du groupe: $e');
    }
  }

  Future<String> getGroupeNomById(String groupeId) async {
    try {
      final doc = await groupesCollection.doc(groupeId).get();
      if (doc.exists) {
        final groupe = Groupe.fromMap(doc.data() as Map<String, dynamic>);
        return groupe.nom;
      }
      return 'Groupe inconnu';
    } catch (e) {
      return 'Erreur de chargement';
    }
  }

  Future<List<Groupe>> getGroupesParFiliere(String filiereId) async {
    try {
      final querySnapshot = await groupesCollection
          .where('filiereId', isEqualTo: filiereId)
          .get();
      return querySnapshot.docs
          .map((doc) => Groupe.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des groupes: $e');
    }
  }

  Future<void> modifierGroupe(Groupe groupe) async {
    try {
      await groupesCollection.doc(groupe.id).update(groupe.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification du groupe: $e');
    }
  }

  Future<void> supprimerGroupe(String groupeId) async {
    try {
      await groupesCollection.doc(groupeId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du groupe: $e');
    }
  }

  Stream<List<Groupe>> getGroupesParFiliereStream(String filiereId) {
    return groupesCollection
        .where('filiereId', isEqualTo: filiereId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Groupe.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getGroupesAvecNombreEtudiantsStream(String filiereId) {
    return groupesCollection
        .where('filiereId', isEqualTo: filiereId)
        .snapshots()
        .asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final groupe = Groupe.fromMap(doc.data() as Map<String, dynamic>);
        final nombreEtudiants = await getNombreEtudiantsParGroupe(groupe.id);

        result.add({
          'groupe': groupe,
          'nombreEtudiants': nombreEtudiants,
        });
      }

      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getGroupesAvecNombreEtudiants(String filiereId) async {
    try {
      final groupes = await getGroupesParFiliere(filiereId);
      final result = <Map<String, dynamic>>[];

      for (final groupe in groupes) {
        final nombreEtudiants = await getNombreEtudiantsParGroupe(groupe.id);
        result.add({
          'groupe': groupe,
          'nombreEtudiants': nombreEtudiants,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors du chargement des groupes avec effectif: $e');
    }
  }

  Stream<int> getNombreEtudiantsParGroupeStream(String groupeId) {
    return etudiantsCollection
        .where('groupeId', isEqualTo: groupeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============ CRUD pour Étudiants ============

  Future<void> ajouterEtudiant(Etudiant etudiant) async {
    try {
      await etudiantsCollection.doc(etudiant.id).set(etudiant.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'étudiant: $e');
    }
  }


  Future<int> getNombreEtudiantsParNiveau(String niveau) async {
    try {
      final querySnapshot = await etudiantsCollection
          .where('niveau', isEqualTo: niveau)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Erreur comptage étudiants par niveau: $e');
      return 0;
    }
  }

  Future<int> getNombreEtudiantsParGroupe(String groupeId) async {
    try {
      final querySnapshot = await etudiantsCollection
          .where('groupeId', isEqualTo: groupeId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print(' Erreur comptage étudiants: $e');
      return 0;
    }
  }

  Future<int> getNombreEtudiantsParFiliere(String filiereId) async {
    try {
      final querySnapshot = await etudiantsCollection
          .where('filiereId', isEqualTo: filiereId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Erreur comptage étudiants par filière: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getEtudiantsAvecDetails(String groupeId) async {
    try {
      final etudiants = await getEtudiantsParGroupe(groupeId);
      final result = <Map<String, dynamic>>[];

      for (final etudiant in etudiants) {
        final filiereNom = await getFiliereNomById(etudiant.filiereId);
        final groupeNom = await getGroupeNomById(etudiant.groupeId);

        result.add({
          'etudiant': etudiant,
          'filiereNom': filiereNom,
          'groupeNom': groupeNom,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails: $e');
    }
  }

  Future<List<Etudiant>> getEtudiantsParGroupe(String groupeId) async {
    try {
      final querySnapshot = await etudiantsCollection
          .where('groupeId', isEqualTo: groupeId)
          .get();
      return querySnapshot.docs
          .map((doc) => Etudiant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des étudiants: $e');
    }
  }

  Future<List<Etudiant>> getTousLesEtudiants() async {
    try {
      final querySnapshot = await etudiantsCollection.get();
      return querySnapshot.docs
          .map((doc) => Etudiant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération de tous les étudiants: $e');
    }
  }

  Future<void> modifierEtudiant(Etudiant etudiant) async {
    try {
      await etudiantsCollection.doc(etudiant.id).update(etudiant.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'étudiant: $e');
    }
  }

  Future<void> supprimerEtudiant(String etudiantId) async {
    try {
      await etudiantsCollection.doc(etudiantId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'étudiant: $e');
    }
  }

  Stream<List<Etudiant>> getEtudiantsParGroupeStream(String groupeId) {
    return etudiantsCollection
        .where('groupeId', isEqualTo: groupeId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Etudiant.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }


  Future<String> getEnseignantNomById(String enseignantId) async {
    try {
      if (enseignantId.isEmpty) return 'Non assigné';

      final doc = await enseignantsCollection.doc(enseignantId).get();
      if (doc.exists) {
        final enseignant = Enseignant.fromMap(doc.data() as Map<String, dynamic>);
        return '${enseignant.prenom} ${enseignant.nom}';
      }
      return 'Enseignant inconnu';
    } catch (e) {
      print('Erreur récupération enseignant: $e');
      return 'Erreur de chargement';
    }
  }


  Future<Map<String, dynamic>> getGroupeAvecDetails(String groupeId) async {
    try {
      final groupeDoc = await groupesCollection.doc(groupeId).get();
      if (!groupeDoc.exists) {
        throw Exception('Groupe non trouvé');
      }

      final groupe = Groupe.fromMap(groupeDoc.data() as Map<String, dynamic>);
      final filiereNom = await getFiliereNomById(groupe.filiereId);

      return {
        'groupe': groupe,
        'filiereNom': filiereNom,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails du groupe: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupesAvecDetailsStream(String filiereId) {
    return groupesCollection
        .where('filiereId', isEqualTo: filiereId)
        .snapshots()
        .asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final groupe = Groupe.fromMap(doc.data() as Map<String, dynamic>);
        final nombreEtudiants = await getNombreEtudiantsParGroupe(groupe.id);

        result.add({
          'groupe': groupe,
          'nombreEtudiants': nombreEtudiants,
        });
      }

      return result;
    });
  }



  Future<void> ajouterEnseignant(Enseignant enseignant) async {
    try {
      await enseignantsCollection.doc(enseignant.id).set(enseignant.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'enseignant: $e');
    }
  }

  Future<List<Enseignant>> getTousLesEnseignants() async {
    try {
      final querySnapshot = await enseignantsCollection.get();
      return querySnapshot.docs
          .map((doc) => Enseignant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des enseignants: $e');
    }
  }

  Future<List<Enseignant>> getEnseignantsParDepartement(String departement) async {
    try {
      final querySnapshot = await enseignantsCollection
          .where('departement', isEqualTo: departement)
          .get();
      return querySnapshot.docs
          .map((doc) => Enseignant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des enseignants par département: $e');
    }
  }

  Future<void> modifierEnseignant(Enseignant enseignant) async {
    try {
      await enseignantsCollection.doc(enseignant.id).update(enseignant.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'enseignant: $e');
    }
  }

  Future<void> supprimerEnseignant(String enseignantId) async {
    try {
      await enseignantsCollection.doc(enseignantId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'enseignant: $e');
    }
  }

  Stream<List<Enseignant>> getEnseignantsStream() {
    return enseignantsCollection.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Enseignant.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Enseignant>> getEnseignantsParDepartementStream(String departement) {
    return enseignantsCollection
        .where('departement', isEqualTo: departement)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Enseignant.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }



  Future<String> getResponsableNomById(String responsableId) async {
    try {
      if (responsableId.isEmpty) return 'Non assigné';

      final doc = await enseignantsCollection.doc(responsableId).get();
      if (doc.exists) {
        final enseignant = Enseignant.fromMap(doc.data() as Map<String, dynamic>);
        return '${enseignant.prenom} ${enseignant.nom}';
      }
      return 'Responsable inconnu';
    } catch (e) {
      print('Erreur récupération responsable: $e');
      return 'Erreur de chargement';
    }
  }

  Future<Map<String, dynamic>> getFiliereAvecDetails(String filiereId) async {
    try {
      final filiereDoc = await filieresCollection.doc(filiereId).get();
      if (!filiereDoc.exists) {
        throw Exception('Filière non trouvée');
      }

      final filiere = Filiere.fromMap(filiereDoc.data() as Map<String, dynamic>);
      final responsableNom = await getResponsableNomById(filiere.responsableId);

      return {
        'filiere': filiere,
        'responsableNom': responsableNom,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails de la filière: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getFilieresAvecDetailsStream(String niveau) {
    return filieresCollection
        .where('niveau', isEqualTo: niveau)
        .snapshots()
        .asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final filiere = Filiere.fromMap(doc.data() as Map<String, dynamic>);
        final nombreEtudiants = await getNombreEtudiantsParFiliere(filiere.id);
        final responsableNom = await getResponsableNomById(filiere.responsableId);

        result.add({
          'filiere': filiere,
          'nombreEtudiants': nombreEtudiants,
          'responsableNom': responsableNom,
        });
      }

      return result;
    });
  }



  // ============ CRUD pour Cours ============

  Future<void> ajouterCours(Cours cours) async {
    try {
      await coursCollection.doc(cours.id).set(cours.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du cours: $e');
    }
  }

  Future<List<Cours>> getTousLesCours() async {
    try {
      final querySnapshot = await coursCollection.get();
      return querySnapshot.docs
          .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours: $e');
    }
  }

  Future<List<Cours>> getCoursParFiliere(String filiereId) async {
    try {
      final querySnapshot = await coursCollection
          .where('filiereId', isEqualTo: filiereId)
          .get();
      return querySnapshot.docs
          .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours par filière: $e');
    }
  }


  Future<Map<String, dynamic>> getStatistiquesEnseignant(String enseignantId) async {
    try {
      final coursQuery = await coursCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();
      final nombreCours = coursQuery.docs.length;

      int nombreEtudiants = await _getNombreEtudiantsParEnseignant(enseignantId);

      final nombreAbsencesMois = await _getAbsencesMoisParEnseignant(enseignantId);

      final prochainsCours = await _getProchainsCoursEnseignant(enseignantId);

      return {
        'cours': nombreCours,
        'etudiants': nombreEtudiants,
        'absences_mois': nombreAbsencesMois,
        'prochains_cours': prochainsCours,
      };
    } catch (e) {
      print('Erreur getStatistiquesEnseignant: $e');
      return {
        'cours': 0,
        'etudiants': 0,
        'absences_mois': 0,
        'prochains_cours': 0,
      };
    }
  }


  Future<int> _getNombreEtudiantsParEnseignant(String enseignantId) async {
    try {
      final coursQuery = await coursCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();

      final coursIds = coursQuery.docs.map((doc) => doc.id).toList();
      if (coursIds.isEmpty) return 0;

      final emploisQuery = await emploiTempsCollection
          .where('coursId', whereIn: coursIds)
          .get();

      final groupeIds = emploisQuery.docs
          .map((doc) => doc['groupeId'] as String)
          .toSet()
          .toList();

      if (groupeIds.isEmpty) return 0;

      int totalEtudiants = 0;
      for (final groupeId in groupeIds) {
        final etudiantsQuery = await etudiantsCollection
            .where('groupeId', isEqualTo: groupeId)
            .get();
        totalEtudiants += etudiantsQuery.docs.length;
      }

      return totalEtudiants;
    } catch (e) {
      print('Erreur _getNombreEtudiantsParEnseignant: $e');
      return 0;
    }
  }

  Future<int> _getAbsencesMoisParEnseignant(String enseignantId) async {
    try {
      final absencesQuery = await absencesCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();

      final debutMois = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final finMois = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

      final absencesDuMois = absencesQuery.docs.where((doc) {
        final absence = Absence.fromMap(doc.data() as Map<String, dynamic>);
        return absence.dateSeance.isAfter(debutMois.subtract(const Duration(seconds: 1))) &&
            absence.dateSeance.isBefore(finMois.add(const Duration(seconds: 1)));
      }).toList();

      return absencesDuMois.length;
    } catch (e) {
      print('Erreur _getAbsencesMoisParEnseignant: $e');
      return 0;
    }
  }

  Future<int> _getProchainsCoursEnseignant(String enseignantId) async {
    try {
      final coursQuery = await coursCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();

      final coursIds = coursQuery.docs.map((doc) => doc.id).toList();
      if (coursIds.isEmpty) return 0;

      final aujourdhui = _getNomJour(DateTime.now().weekday);
      final maintenant = TimeOfDay.now();
      int prochainsCours = 0;

      for (final coursId in coursIds) {
        final emploisQuery = await emploiTempsCollection
            .where('coursId', isEqualTo: coursId)
            .get();

        for (final doc in emploisQuery.docs) {
          final emploi = EmploiTemps.fromMap(doc.data() as Map<String, dynamic>);

          if (emploi.jour == aujourdhui) {
            final heureFinMinutes = emploi.heureFin.hour * 60 + emploi.heureFin.minute;
            final maintenantMinutes = maintenant.hour * 60 + maintenant.minute;

            if (maintenantMinutes < heureFinMinutes) {
              prochainsCours++;
            }
          }
        }
      }

      return prochainsCours;
    } catch (e) {
      print('Erreur _getProchainsCoursEnseignant: $e');
      return 0;
    }
  }

  String _getNomJour(int weekday) {
    final jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return jours[weekday];
  }

  Future<List<Absence>> getAbsencesParEnseignant(String enseignantId) async {
    try {
      final querySnapshot = await absencesCollection
          .where('enseignantId', isEqualTo: enseignantId)
          .get();

      return querySnapshot.docs
          .map((doc) => Absence.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des absences par enseignant: $e');
    }
  }

  Future<List<Cours>> getCoursParNiveau(String niveau) async {
    try {
      final querySnapshot = await coursCollection
          .where('niveau', isEqualTo: niveau)
          .get();
      return querySnapshot.docs
          .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours par niveau: $e');
    }
  }

  Future<void> modifierCours(Cours cours) async {
    try {
      await coursCollection.doc(cours.id).update(cours.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification du cours: $e');
    }
  }

  Future<void> supprimerCours(String coursId) async {
    try {
      await coursCollection.doc(coursId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du cours: $e');
    }
  }

  Stream<List<Cours>> getCoursStream() {
    return coursCollection.snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Cours.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Map<String, dynamic>> getCoursAvecDetails(String coursId) async {
    try {
      final coursDoc = await coursCollection.doc(coursId).get();
      if (!coursDoc.exists) {
        throw Exception('Cours non trouvé');
      }

      final cours = Cours.fromMap(coursDoc.data() as Map<String, dynamic>);
      final enseignantNom = await getEnseignantNomById(cours.enseignantId);
      final filiereNom = await getFiliereNomById(cours.filiereId);

      return {
        'cours': cours,
        'enseignantNom': enseignantNom,
        'filiereNom': filiereNom,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails du cours: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCoursAvecDetailsStream() {
    return coursCollection.snapshots().asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final cours = Cours.fromMap(doc.data() as Map<String, dynamic>);
        final enseignantNom = await getEnseignantNomById(cours.enseignantId);
        final filiereNom = await getFiliereNomById(cours.filiereId);

        result.add({
          'cours': cours,
          'enseignantNom': enseignantNom,
          'filiereNom': filiereNom,
        });
      }

      return result;
    });
  }



  // ============ CRUD pour Emploi du Temps ============

  Future<void> ajouterEmploiTemps(EmploiTemps emploiTemps) async {
    try {
      await emploiTempsCollection.doc(emploiTemps.id).set(emploiTemps.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du créneau: $e');
    }
  }

  Future<List<EmploiTemps>> getEmploiTempsParGroupe(String groupeId) async {
    try {
      final querySnapshot = await emploiTempsCollection
          .where('groupeId', isEqualTo: groupeId)
          .get();
      return querySnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'emploi du temps: $e');
    }
  }

  Future<List<EmploiTemps>> getEmploiTempsParJourEtGroupe(String groupeId, String jour) async {
    try {
      final querySnapshot = await emploiTempsCollection
          .where('groupeId', isEqualTo: groupeId)
          .where('jour', isEqualTo: jour)
          .get();
      return querySnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'emploi du temps: $e');
    }
  }

  Future<bool> verifierConflitEmploiTemps({
    required String groupeId,
    required String jour,
    required TimeOfDay heureDebut,
    required TimeOfDay heureFin,
    String? emploiTempsId,
  }) async {
    try {
      final querySnapshot = await emploiTempsCollection
          .where('groupeId', isEqualTo: groupeId)
          .where('jour', isEqualTo: jour)
          .get();

      final emplois = querySnapshot.docs
          .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
          .where((emploi) => emploi.id != emploiTempsId)
          .toList();

      final nouveauCreneau = EmploiTemps(
        id: '',
        groupeId: groupeId,
        coursId: '',
        jour: jour,
        heureDebut: heureDebut,
        heureFin: heureFin,
        salle: '',
        dateCreation: DateTime.now(),
      );

      for (final emploi in emplois) {
        if (emploi.chevaucheAvec(nouveauCreneau)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Erreur lors de la vérification des conflits: $e');
    }
  }

  Future<void> modifierEmploiTemps(EmploiTemps emploiTemps) async {
    try {
      await emploiTempsCollection.doc(emploiTemps.id).update(emploiTemps.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la modification du créneau: $e');
    }
  }

  Future<void> supprimerEmploiTemps(String emploiTempsId) async {
    try {
      await emploiTempsCollection.doc(emploiTempsId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du créneau: $e');
    }
  }

  Stream<List<EmploiTemps>> getEmploiTempsParGroupeStream(String groupeId) {
    return emploiTempsCollection
        .where('groupeId', isEqualTo: groupeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EmploiTemps.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<Map<String, dynamic>> getEmploiTempsAvecDetails(String emploiTempsId) async {
    try {
      final emploiDoc = await emploiTempsCollection.doc(emploiTempsId).get();
      if (!emploiDoc.exists) {
        throw Exception('Créneau non trouvé');
      }

      final emploiTemps = EmploiTemps.fromMap(emploiDoc.data() as Map<String, dynamic>);
      final coursDetails = await getCoursAvecDetails(emploiTemps.coursId);
      final groupeDetails = await getGroupeAvecDetails(emploiTemps.groupeId);

      return {
        'emploiTemps': emploiTemps,
        'cours': coursDetails['cours'],
        'enseignantNom': coursDetails['enseignantNom'],
        'filiereNom': coursDetails['filiereNom'],
        'groupeNom': groupeDetails['groupe'].nom,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getEmploiTempsAvecDetailsStream(String groupeId) {
    return emploiTempsCollection
        .where('groupeId', isEqualTo: groupeId)
        .snapshots()
        .asyncMap((snapshot) async {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final emploiTemps = EmploiTemps.fromMap(doc.data() as Map<String, dynamic>);
        final coursDetails = await getCoursAvecDetails(emploiTemps.coursId);
        final groupeDetails = await getGroupeAvecDetails(emploiTemps.groupeId);

        result.add({
          'emploiTemps': emploiTemps,
          'cours': coursDetails['cours'],
          'enseignantNom': coursDetails['enseignantNom'],
          'filiereNom': coursDetails['filiereNom'],
          'groupeNom': groupeDetails['groupe'].nom,
        });
      }

      return result;
    });
  }


}
