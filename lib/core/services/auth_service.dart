import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin.dart';
import '../models/enseignant.dart';
import '../models/etudiant.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<UserCredential> _createUserInAuth(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<Enseignant> createEnseignant({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
  }) async {
    try {
      final userCredential = await _createUserInAuth(email, motDePasse);
      final userId = userCredential.user!.uid;

      final enseignant = Enseignant(
        id: userId,
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        etat: 'actif',
        dateAjout: DateTime.now(),
      );

      await _firestore.collection('enseignants').doc(userId).set(enseignant.toMap());

      return enseignant;
    } catch (e) {
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<Etudiant> createEtudiant({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String cin,
    required String cne,
    required String filiereId,
    required String groupeId,
    required String niveau,
    required String telephone,
    required String adresse,
    required DateTime dateNaissance,
    required String lieuNaissance,
    required String nationalite,
  }) async {
    try {
      final userCredential = await _createUserInAuth(email, motDePasse);
      final userId = userCredential.user!.uid;

      final etudiant = Etudiant(
        id: userId,
        nom: nom,
        prenom: prenom,
        email: email,
        cin: cin,
        cne: cne,
        filiereId: filiereId,
        groupeId: groupeId,
        niveau: niveau,
        etat: 'actif',
        motDePasse: motDePasse,
        dateInscription: DateTime.now(),
        telephone: telephone,
        adresse: adresse,
        dateNaissance: dateNaissance,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
      );

      await _firestore.collection('etudiants').doc(userId).set(etudiant.toMap());

      return etudiant;
    } catch (e) {
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<dynamic> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (adminDoc.exists) {
        return Admin.fromMap(adminDoc.data()!);
      }

      final enseignantDoc = await _firestore.collection('enseignants').doc(userId).get();
      if (enseignantDoc.exists) {
        return Enseignant.fromMap(enseignantDoc.data()!);
      }

      final etudiantDoc = await _firestore.collection('etudiants').doc(userId).get();
      if (etudiantDoc.exists) {
        return Etudiant.fromMap(etudiantDoc.data()!);
      }

      await _auth.signOut();
      throw Exception('Aucun compte trouvé avec ces identifiants');

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }


  Future<Admin?> signInAdmin(String email, String password) async {
    try {
      final user = await signIn(email, password);
      if (user is Admin) {
        return user;
      }
      await _auth.signOut();
      throw Exception('Accès réservé aux administrateurs');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<dynamic> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final userId = firebaseUser.uid;

      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (adminDoc.exists) {
        return Admin.fromMap(adminDoc.data()!);
      }

      final enseignantDoc = await _firestore.collection('enseignants').doc(userId).get();
      if (enseignantDoc.exists) {
        return Enseignant.fromMap(enseignantDoc.data()!);
      }

      final etudiantDoc = await _firestore.collection('etudiants').doc(userId).get();
      if (etudiantDoc.exists) {
        return Etudiant.fromMap(etudiantDoc.data()!);
      }

      return null;
    });
  }

  Future<dynamic> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final userId = firebaseUser.uid;

    final adminDoc = await _firestore.collection('admins').doc(userId).get();
    if (adminDoc.exists) {
      return Admin.fromMap(adminDoc.data()!);
    }

    final enseignantDoc = await _firestore.collection('enseignants').doc(userId).get();
    if (enseignantDoc.exists) {
      return Enseignant.fromMap(enseignantDoc.data()!);
    }

    final etudiantDoc = await _firestore.collection('etudiants').doc(userId).get();
    if (etudiantDoc.exists) {
      return Etudiant.fromMap(etudiantDoc.data()!);
    }

    return null;
  }

  bool get isLoggedIn => _auth.currentUser != null;

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur de connexion: ${e.message}';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
