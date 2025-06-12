import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  // get instance of firebase auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get user data from firestore
   Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }
  

  // get current user
  User? getCurrentUser(){
    return _firebaseAuth.currentUser;
  }




  // sign in
  Future<UserCredential> signInwithEmailPassword(String email, password) async{
    try{
      // try sign user in
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      return userCredential;
    }
    // catch errors
    on FirebaseAuthException catch(e){
      throw Exception(e.code);
    }

  }
  



  // sign up
  Future<UserCredential> signUpwithEmailPassword(String email, password) async{
    try{
      // try sign user up
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      return userCredential;
    }
    // catch errors
    on FirebaseAuthException catch(e){
      throw Exception(e.code);
    }

  }



  // sign out
  Future<void> signOut() async{
    return await _firebaseAuth.signOut();
  }

  

}