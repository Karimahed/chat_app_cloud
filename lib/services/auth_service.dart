import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signUpWithEmailPassword(String email, String password,
      String username, String phone, File? selectedImage) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        String imageUrl = "";
        if (selectedImage != null) {
          imageUrl =
              await uploadProfileImage(userCredential.user!.uid, selectedImage);
        }

        await saveUserData(
            user: userCredential.user!,
            username: username,
            email: email,
            phone: phone,
            imageUrl: imageUrl);
      }

      return userCredential;
    } catch (e) {
      print('Error signing up with email and password: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print('Error signing in with email and password: $e');
      return null;
    }
  }

  Future<String> uploadProfileImage(String userId, File? selectedImage) async {
    try {
      if (selectedImage == null) {
        throw "No image selected!";
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${userId}.jpg');

      await storageRef.putFile(selectedImage);
      final imageURL = await storageRef.getDownloadURL();

      if (imageURL.isEmpty) {
        throw "Failed to retrieve image URL.";
      }

      return imageURL;
    } catch (error) {
      throw "Error uploading image: $error";
    }
  }

  Future<void> saveUserData(
      {required User user,
      required String username,
      String? email,
      String? phone,
      required String imageUrl}) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'username': username,
        'email': email,
        'phone': phone,
        'imageURL': imageUrl,
      });
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  Future<void> sendOtp(
      String phoneNumber,
      Function verificationCompleted,
      Function verificationFailed,
      Function codeSent,
      Function codeAutoRetrievalTimeout) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Handle automatic sign-in (e.g., on Android with reCAPTCHA)
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException error) {
          // Handle failure (e.g., invalid phone number)
          verificationFailed(error);
        },
        codeSent: (String verificationId, int? resendToken) {
          // Called when the OTP is sent
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called when auto-retrieval times out (e.g., reCAPTCHA challenge failure)
          codeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      print('Error sending OTP: $e');
    }
  }

  Future<UserCredential?> verifyOtp(String verificationId, String otp) async {
    try {
      final phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: otp);
      return await _firebaseAuth.signInWithCredential(phoneAuthCredential);
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
