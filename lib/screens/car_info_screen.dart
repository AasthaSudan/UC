import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project_1/screens/splash.dart';
import '../global/global.dart';

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

  @override
  void dispose() {
    carModelTextEditingController.dispose();
    carNumberTextEditingController.dispose();
    carColorTextEditingController.dispose();
    super.dispose();
  }

  _submit() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Map<String, dynamic> driverCarInfoMap = {
        "car_color": carColorTextEditingController.text.trim(),
        "car_number": carNumberTextEditingController.text.trim(),
        "car_model": carModelTextEditingController.text.trim(),
        "car_type": selectedCarType,
      };

      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child("Drivers")
          .child(currentUser!.uid)
          .child("car_details");

      await ref.set(driverCarInfoMap);

      if (mounted) Navigator.pop(context);

      Fluttertoast.showToast(
        msg: "Car Details Submitted Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => SplashScreen()),
              (route) => false,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please fill all fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset(
                  darkTheme ? 'assets/images/img_1.png' : 'assets/images/img_2.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                ),
                const SizedBox(height: 20),
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
                          icon: Icons.directions_car,
                          hint: "Car Model (e.g., Honda City)",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car model cannot be empty';
                            }
                            if (text.length < 2) {
                              return 'Car model must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _inputField(
                          darkTheme: darkTheme,
                          controller: carNumberTextEditingController,
                          icon: Icons.confirmation_number,
                          hint: "Car Number (e.g., DL01AB1234)",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car number cannot be empty';
                            }
                            if (text.length < 5) {
                              return 'Please enter a valid car number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _inputField(
                          darkTheme: darkTheme,
                          controller: carColorTextEditingController,
                          icon: Icons.color_lens,
                          hint: "Car Color (e.g., White)",
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Car color cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: selectedCarType,
                          items: carTypes.map((String carType) {
                            return DropdownMenuItem<String>(
                              value: carType,
                              child: Text(
                                carType,
                                style: TextStyle(
                                  color: darkTheme ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCarType = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Select Car Type",
                            hintStyle: TextStyle(
                              color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.category,
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            ),
                            filled: true,
                            fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: darkTheme ? Colors.grey.shade800 : Colors.white,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a car type';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            foregroundColor: darkTheme ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 3,
                          ),
                          onPressed: _submit,
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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
      style: TextStyle(
        color: darkTheme ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        ),
        filled: true,
        fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
        hintText: hint,
        hintStyle: TextStyle(
          color: darkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(
            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }
}