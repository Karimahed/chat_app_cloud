import 'package:chat_app/screens/registration_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/widgets/my_button.dart';
import 'package:chat_app/widgets/text_field.dart';

import '../widgets/square_tile.dart';
import 'channels_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final otpController = TextEditingController();

  bool _isAuthenticating = false;
  bool _isPhoneLogin = false;
  bool _otpSent = false;
  String _verificationId = '';
  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  void signUserIn() async {
    final email = usernameController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final userCredential = await _authService.signInWithEmailPassword(email, password);

      if (userCredential != null) {
        // Log analytics event
        await _analyticsService.login(email, 'Email');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ChannelsScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void sendOtp() async {
    final phoneNumber = phoneNumberController.text;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number")),
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      await _authService.sendOtp(
        phoneNumber,
            (credential) {
          // Optional: handle auto-sign-in if applicable
        },
            (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Phone verification failed.')),
          );
        },
            (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your phone")),
          );
        },
            (verificationId) {
          // Handle timeout logic if needed
        },
      );


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void verifyOtp() async {
    final otp = otpController.text;

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    try {
      final userCredential = await _authService.verifyOtp(_verificationId, otp);

      if (userCredential != null) {

        await _analyticsService.login(phoneNumberController.text, 'Phone');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ChannelsScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verification failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChatApp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.chat_rounded,
                    size: 90,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back you\'ve been missed!',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (!_isPhoneLogin) ...[
                    MyTextField(
                      controller: usernameController,
                      hintText: 'Email Address',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                  ] else
                    ...[
                      MyTextField(
                        controller: phoneNumberController,
                        hintText: 'Phone Number',
                        obscureText: false,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: MyTextField(
                              controller: otpController,
                              hintText: "Enter OTP",
                              obscureText: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 25),
                            child: ElevatedButton(
                              key: const Key('verifyPhoneButton'),
                              onPressed: sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                minimumSize: const Size(100, 48),
                              ),
                              child: const Text(
                                "Send OTP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  const SizedBox(height: 15),
                  MyButton(
                      onTap: _isPhoneLogin ? verifyOtp : signUserIn,
                      buttonText: "Sign In",
                      key: const Key('signInButton')
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                      key: const Key('toggleLoginMethodButton'),
                      onPressed: () async {
                      setState(() {
                        _isPhoneLogin = !_isPhoneLogin;
                      });


                    },
                    child: Text(
                      _isPhoneLogin
                          ? "Login with Email and Password"
                          : "Login with Phone Number?",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        key: const Key('googleSignInButton'),
                        onTap: () async {
                          try {
                            final userCredential = await _authService.signInWithGoogle();

                            final username = userCredential?.user!.displayName ?? 'Unknown User';

                            await _analyticsService.login(username, 'Google');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Google sign-in failed: $e')),
                            );
                          }
                        },
                        imagePath: 'lib/images/google.png',
                      ),

                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
