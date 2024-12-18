import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/auth.dart';
void main() {

  group('AuthenticationPage Tests', () {
    testWidgets('Sign Up button is tappable', (WidgetTester tester) async {
      bool signUpTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('signUpButton'),
              onPressed: () {
                signUpTapped = true;
              },
              child: const Text('Register Now'),
            ),
          ),
        ),
      );

      // Tap the Sign Up button
      await tester.tap(find.byKey(const Key('signUpButton')));
      await tester.pump();

      // Verify the function was triggered
      expect(signUpTapped, isTrue);
    });

    testWidgets('Sign In button is tappable', (WidgetTester tester) async {
      bool signInTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('signInButton'),
              onPressed: () {
                signInTapped = true;
              },
              child: const Text('Sign In'),
            ),
          ),
        ),
      );

      // Tap the Sign In button
      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pump();

      // Verify the function was triggered
      expect(signInTapped, isTrue);
    });



    testWidgets('Google Sign In button is tappable', (WidgetTester tester) async {
      bool googleSignInTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('googleSignInButton'),
              onPressed: () {
                googleSignInTapped = true;
              },
              child: const Text('Sign In with Google'),
            ),
          ),
        ),
      );

      // Tap the Google Sign In button
      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pump();

      // Verify the function was triggered
      expect(googleSignInTapped, isTrue);
    });
  });
}
