import 'package:flutter/material.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({super.key});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  final carModelTextEditingController = TextEditingController();
  final carNumberTextEditingController = TextEditingController();
  final carColorTextEditingController = TextEditingController();

  List<String> carTypes = ["Car", "CNG", "Bike"];
  String? selectedCarType;

  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  Widget build(BuildContext context) {
    bool darkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset(
                  darkTheme ? 'assets/images/img_1.png' : 'assets/images/img_2.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                ),
                SizedBox(height: 20),
                Text(
                  "Add Car Details",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: darkTheme ? Colors.amber.shade400 : Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 50),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _inputField(
                          darkTheme: darkTheme,
                          controller: carModelTextEditingController,
                          icon: Icons.car_repair,
                          hint: "Car Model",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car model cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _inputField(
                          darkTheme: darkTheme,
                          controller: carNumberTextEditingController,
                          icon: Icons.numbers,
                          hint: "Car Number",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car number cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _inputField(
                          darkTheme: darkTheme,
                          controller: carColorTextEditingController,
                          icon: Icons.color_lens,
                          hint: "Car Color",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car color cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Car Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCarType,
                          items: carTypes.map((String carType) {
                            return DropdownMenuItem<String>(
                              value: carType,
                              child: Text(carType),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCarType = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Select Car Type",
                            filled: true,
                            fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a car type';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            foregroundColor: darkTheme ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Car Details Submitted')),
                              );
                            }
                          },
                          child: const Text(
                            "Submit", // Changed from Register to Submit
                            style: TextStyle(fontSize: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            // Add navigation for Forgot Password if necessary
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Doesn't have an account?",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                // Add navigation for Register if necessary
                              },
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                ),
                              ),
                            ),
                          ],
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

  Widget _inputField({
    required bool darkTheme,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        ),
        filled: true,
        fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
