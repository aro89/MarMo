import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madmet/pages/create_account.dart';
import 'package:madmet/widgets_authentication/custom_input_field.dart';
import 'package:madmet/widgets_authentication/custom_button.dart';
import 'dashboard.dart';

import 'package:madmet/firestore_service.dart';
import 'package:madmet/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'forgot_password.dart';


class LoginPage extends StatefulWidget {
  static route() => MaterialPageRoute(
    builder: (context) => const LoginPage(),
  );
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Check if Firestore user exists
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Create Firestore user if it doesn't exist
        if (!userDoc.exists) {
          final newUser = AppUser(
            uid: user.uid,
            totalBalance: 0.0,
            totalIncome: 0.0,
            totalExpense: 0.0,
          );
          await FirestoreService().createUser(newUser);
        }

        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Dashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An unknown error occurred'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text with Padding
              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: Text(
                  'Hey,\nWelcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Image
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.25,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/welcome.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 5.0),
                child: Text(
                  'Login now to track your expenses',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Center text fields and button
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: Column(
                    children: [
                      CustomInputField(
                        controller: emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email is required';
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomInputField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'SIGN IN',
                        isLoading: isLoading,
                        onPressed: loginUserWithEmailAndPassword,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Sign Up Text
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, CreateAccountPage.route()),
                  child: RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Forgot Password Link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, ForgotPasswordPage.route()),
                  child: Text(
                    'Forgot your password?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
