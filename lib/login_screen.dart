import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'main_screen.dart';
import 'global.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;

  // LOGIN FUNCTION
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      UserCredential auth = await firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      currentUser = auth.user;

      if (currentUser != null) {
        Fluttertoast.showToast(msg: "Logged in Successfully");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Login failed");
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
                  'Login',
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // EMAIL
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

                        const SizedBox(height: 20),

                        // PASSWORD
                        _passwordField(
                          darkTheme: darkTheme,
                          controller: passwordController,
                          hint: "Password",
                          visible: _passwordVisible,
                          onToggleVisibility: () {
                            setState(() => _passwordVisible = !_passwordVisible);
                          },
                        ),

                        const SizedBox(height: 30),

                        // LOGIN BUTTON
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
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // REGISTER LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to Register Screen
                              },
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  color: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        )
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

// REUSE YOUR INPUT FIELD
Widget _inputField({
  required bool darkTheme,
  required TextEditingController controller,
  required IconData icon,
  required String hint,
  required String? Function(String?) validator,
}) {
  return TextFormField(
    controller: controller,
    inputFormatters: [LengthLimitingTextInputFormatter(100)],
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(
        icon,
        color: darkTheme ? Colors.amber.shade400 : Colors.grey,
      ),
    ),
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
}

// PASSWORD FIELD
Widget _passwordField({
  required bool darkTheme,
  required TextEditingController controller,
  required String hint,
  required bool visible,
  required VoidCallback onToggleVisibility,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: !visible,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(
        Icons.lock,
        color: darkTheme ? Colors.amber.shade400 : Colors.grey,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility : Icons.visibility_off,
          color: darkTheme ? Colors.amber.shade400 : Colors.grey,
        ),
        onPressed: onToggleVisibility,
      ),
    ),
    validator: validator ??
            (text) {
          if (text == null || text.isEmpty) {
            return 'Password cannot be empty';
          }
          if (text.length < 6) return "Minimum 6 characters";
          return null;
        },
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
}
