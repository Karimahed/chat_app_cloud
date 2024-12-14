import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../widgets/my_button.dart';
import '../widgets/text_field.dart';
import '../widgets/user_image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _analyticsService = AnalyticsService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  File? _selectedImage;
  bool _isPhoneRegistration = false;
  bool _isOtpSent = false;
  bool _isAuthenticating = false;

  String? _verificationId;

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and add an image.")),
      );
      return;
    }

    try {
      setState(() => _isAuthenticating = true);

      final userCredential = await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _phoneController.text.trim(),
        _selectedImage,
      );

      if (userCredential == null) {
        return;
      }

      await _analyticsService.register(
          _usernameController.text.trim(), 'Email');
      await _analyticsService.login(_usernameController.text.trim(), 'Email');

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number.")),
      );
      return;
    }

    try {
      setState(() => _isAuthenticating = true);

      await _authService.sendOtp(
        _phoneController.text.trim(),
        (PhoneAuthCredential credential) async {},
        (FirebaseAuthException error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Verification failed.')),
          );
        },
        (String verificationId) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your phone.")),
          );
        },
        (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP.")),
      );
      return;
    }

    try {
      setState(() => _isAuthenticating = true);

      final userCredential = await _authService.verifyOtp(
          _verificationId!, _otpController.text.trim());

      if (userCredential == null) {
        return;
      }

      final imageURL = await _authService.uploadProfileImage(
          userCredential.user!.uid, _selectedImage);
      await _authService.saveUserData(
        user: userCredential.user!,
        username: _usernameController.text,
        phone: _phoneController.text,
        imageUrl: imageURL,
      );

      await _analyticsService.register(
          _usernameController.text.trim(), 'Phone');
      await _analyticsService.login(_usernameController.text.trim(), 'Phone');

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: UserImagePicker(
                    onPickImage: (image) {
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MyTextField(
                        controller: _usernameController,
                        hintText: "Username",
                        obscureText: false,
                      ),
                      const SizedBox(height: 20),
                      if (!_isPhoneRegistration) ...[
                        MyTextField(
                          controller: _emailController,
                          hintText: "Email",
                          obscureText: false,
                        ),
                        const SizedBox(height: 20),
                        MyTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          obscureText: true,
                        ),
                      ] else ...[
                        MyTextField(
                          controller: _phoneController,
                          hintText: "Phone Number",
                          obscureText: false,
                        ),
                        const SizedBox(height: 20),
                        if (_isOtpSent)
                          MyTextField(
                            controller: _otpController,
                            hintText: "OTP",
                            obscureText: false,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isAuthenticating) const CircularProgressIndicator(),
                if (!_isAuthenticating)
                  MyButton(
                    onTap: _isPhoneRegistration
                        ? (_isOtpSent ? _verifyOtp : _sendOtp)
                        : _registerWithEmail,
                    buttonText: _isPhoneRegistration
                        ? (_isOtpSent ? "Verify OTP" : "Send OTP")
                        : "Register with Email",
                  ),
                TextButton(
                  onPressed: () {
                    setState(
                        () => _isPhoneRegistration = !_isPhoneRegistration);
                  },
                  child: Text(_isPhoneRegistration
                      ? "Register with Email"
                      : "Register with Phone"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
