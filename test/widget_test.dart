import 'package:chat_app/screens/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mocking the Firebase initialization process
class MockFirebaseCore extends Mock implements FirebaseApp {}

void main() {
  // Ensure Firebase is initialized for tests
  setUpAll(() async {
    // Initialize the Firebase mock or mock the initialization process
    WidgetsFlutterBinding.ensureInitialized();

    // Bypass the actual initialization process with mocked data
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'your-api-key',  // Replace with your actual mock data
        appId: 'your-app-id',
        messagingSenderId: 'your-sender-id',
        projectId: 'your-project-id',
        storageBucket: 'your-storage-bucket',
        authDomain: 'your-auth-domain',
        measurementId: 'your-measurement-id',
      ),
    );
  });

  group('AuthScreen Tests', () {
    testWidgets('Sign In button is tappable and triggers sign-in function', (WidgetTester tester) async {
      bool signInTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Find the Sign In button and tap it
      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pump();

      // Verify that the sign-in function was triggered
      expect(signInTapped, isTrue);
    });

    testWidgets('Sign Up button navigates to registration screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Find the "Register now" button and tap it
      await tester.tap(find.text('Register now'));
      await tester.pumpAndSettle();

      // Verify that the registration screen is displayed
      expect(find.text('Sign Up'), findsOneWidget);  // Assuming 'Sign Up' is part of the Registration screen
    });

    testWidgets('Verify Phone button is tappable and triggers phone verification', (WidgetTester tester) async {
      bool phoneVerifyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Switch to Phone login view by tapping the toggle text
      await tester.tap(find.text('Login with Phone Number?'));
      await tester.pumpAndSettle();

      // Tap the "Send OTP" button to trigger phone verification
      await tester.tap(find.byKey(const Key('verifyPhoneButton')));
      await tester.pump();

      // Verify the phone verification function was triggered
      expect(phoneVerifyTapped, isTrue);
    });

    testWidgets('Google Sign In button is tappable and triggers Google login', (WidgetTester tester) async {
      bool googleSignInTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Tap the Google Sign In button
      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pump();

      // Verify that Google sign-in was triggered
      expect(googleSignInTapped, isTrue);
    });
  });
}
