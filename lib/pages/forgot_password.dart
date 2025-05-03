import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madmet/widgets_authentication/custom_input_field.dart';
import 'package:madmet/widgets_authentication/custom_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  static route() => MaterialPageRoute(
    builder: (context) => const ForgotPasswordPage(),
  );

  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);  // Navigate back to the login page after sending the email
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
              // Forgot Password Text with Padding
              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: Text(
                  'Forgot\nPassword?',
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
                    image: AssetImage("assets/images/forgot.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 5.0),
                child: Text(
                  'Enter your email address to receive a password reset link.',
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
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'SEND RESET LINK',
                        isLoading: isLoading,
                        onPressed: resetPassword,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Back to Login Text
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Remember your password? ',
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: 'Login',
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
