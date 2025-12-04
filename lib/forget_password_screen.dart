import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      Fluttertoast.showToast(
          msg: "Password reset link sent to your email");

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Error occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                const SizedBox(height: 40),

                Image.asset(
                  darkTheme
                      ? 'assets/images/img_1.png'
                      : 'assets/images/img_2.png',
                ),

                const SizedBox(height: 20),

                Text(
                  'Forgot Password',
                  style: TextStyle(
                    color:
                    darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Enter your email to receive reset link",
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // EMAIL FIELD
                        _inputField(
                          darkTheme: darkTheme,
                          controller: emailController,
                          icon: Icons.email,
                          hint: "Email",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Email cannot be empty';
                            }
                            if (!EmailValidator.validate(text)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // SEND BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkTheme
                                ? Colors.amber.shade400
                                : Colors.blue,
                            foregroundColor:
                            darkTheme ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize:
                            const Size(double.infinity, 50),
                          ),
                          onPressed: _resetPassword,
                          child: const Text(
                            "Send Reset Link",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse INPUT FIELD widget from your UI
Widget _inputField({
  required bool darkTheme,
  required TextEditingController controller,
  required IconData icon,
  required String hint,
  required String? Function(String?) validator,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor:
      darkTheme ? Colors.black45 : Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(
        icon,
        color:
        darkTheme ? Colors.amber.shade400 : Colors.grey,
      ),
    ),
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
}
