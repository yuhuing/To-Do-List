import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // exception: invalid email format/password length < 6 (rule from google firebase authentication)/user alr exist
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      log('Firebase Error: ${e.message}', name: 'MyApp', error: e);
      rethrow; 
    } catch (e) {
      log(
        'Something went wrong: $e',
        name: 'MyApp',
        level: 1000, // Level.SEVERE
        error: e,
      );
    }
    return null;
  }

  // exception: invalid email format/password length < 6/user not found
  Future<User?> loginUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      log("Firebase Error: ${e.message}", name: 'MyApp', error: e);
      rethrow;
    } catch (e) {
      log(
        "Something went wrong: $e",
        name: 'MyApp',
        level: 1000, // Level.SEVERE
        error: e,
      );
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Something went wrong");
    }
  }
}
