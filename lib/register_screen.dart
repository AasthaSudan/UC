import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final confirmTextEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

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
                Image.asset(
                  darkTheme ? 'assets/images/img_1.png' : 'assets/images/img_2.png',
                ),
                const SizedBox(height: 20),
                Text(
                  'Register',
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 50),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // NAME FIELD
                        _inputField(
                          darkTheme: darkTheme,
                          controller: nameTextEditingController,
                          icon: Icons.person,
                          hint: "Name",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Name cannot be empty';
                            }
                            if (text.length < 2) return "Enter a valid name";
                            if (text.length > 50) return "Max 50 characters";
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // EMAIL FIELD
                        _inputField(
                          darkTheme: darkTheme,
                          controller: emailTextEditingController,
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

                        const SizedBox(height: 10),

                        // PHONE FIELD
                        IntlPhoneField(
                          controller: phoneTextEditingController,
                          showCountryFlag: false,
                          dropdownIcon: Icon(
                            Icons.arrow_drop_down,
                            color:
                            darkTheme ? Colors.amber.shade400 : Colors.grey,
                          ),
                          decoration: InputDecoration(
                            hintText: "Phone Number",
                            filled: true,
                            fillColor: darkTheme
                                ? Colors.black45
                                : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          initialCountryCode: 'IN',
                        ),

                        const SizedBox(height: 10),

                        // ADDRESS FIELD
                        _inputField(
                          darkTheme: darkTheme,
                          controller: addressTextEditingController,
                          icon: Icons.home,
                          hint: "Address",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Address cannot be empty';
                            }
                            if (text.length < 3) {
                              return "Enter a valid address";
                            }
                            if (text.length > 100) {
                              return "Max 100 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // PASSWORD FIELD
                        _passwordField(
                          darkTheme: darkTheme,
                          controller: passwordTextEditingController,
                          hint: "Password",
                          visible: _passwordVisible,
                          onToggleVisibility: () {
                            setState(() => _passwordVisible = !_passwordVisible);
                          },
                        ),

                        const SizedBox(height: 10),

                        // CONFIRM PASSWORD FIELD
                        _passwordField(
                          darkTheme: darkTheme,
                          controller: confirmTextEditingController,
                          hint: "Confirm Password",
                          visible: _confirmVisible,
                          onToggleVisibility: () {
                            setState(() => _confirmVisible = !_confirmVisible);
                          },
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Confirm Password cannot be empty';
                            }
                            if (text != passwordTextEditingController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            darkTheme ? Colors.amber.shade400 : Colors.blue,
                            foregroundColor:
                            darkTheme ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Register logic
                            }
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------- COMPONENTS -----------

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
}
