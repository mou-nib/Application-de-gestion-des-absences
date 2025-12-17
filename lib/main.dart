import 'package:abs_tracker_f/ui/app.dart';
import 'package:abs_tracker_f/ui/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'blocs/auth/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: authService),
        ),

        // Provider pour Firestore
        Provider<FirestoreService>(
          create: (context) => firestoreService,
        ),

        Provider<AuthService>(
          create: (context) => authService,
        ),

      ],
      child: MaterialApp(
        title: 'Gestion des Absences',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        home: App(authService: authService),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
