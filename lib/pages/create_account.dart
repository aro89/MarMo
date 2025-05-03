import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madmet/pages/dashboard.dart';
import 'package:madmet/pages/login.dart';
import 'package:madmet/widgets_authentication/custom_input_field.dart';
import 'package:madmet/widgets_authentication/custom_button.dart';

import 'package:madmet/models/user_model.dart';
import 'package:madmet/firestore_service.dart';

class CreateAccountPage extends StatefulWidget {
  static route() => MaterialPageRoute(
    builder: (context) => const CreateAccountPage(),
  );
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
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

  Future<void> createUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Create Firestore user record
        final appUser = AppUser(
          uid: user.uid,
          totalBalance: 0.0,
          totalIncome: 0.0,
          totalExpense: 0.0,
        );
        await FirestoreService().createUser(appUser);

        // Navigate to Dashboard
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
        child: Form(  // Add the Form widget here at a higher level
          key: formKey,  // Connect your formKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: Text(
                  'Let\'s\nGet Started',
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
                    image: AssetImage("assets/images/signup.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 5.0),
                child: Text(
                  'Create an account to start tracking your financial expenses now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
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
                          if (value.length < 6) return 'Minimum 6 characters required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'SIGN UP',
                        isLoading: isLoading,
                        onPressed: createUserWithEmailAndPassword,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Already have an account text
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, LoginPage.route()),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: 'Sign In',
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
            ],
          ),
        ),
      ),
    );
  }
}
