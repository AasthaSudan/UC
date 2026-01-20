import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../global/global.dart';
import 'splash.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();

  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("drivers");

  Future<void> showDriverNameDialogAlert(BuildContext context, String name) async {
    nameTextEditingController.text = name;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Driver Name"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameTextEditingController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                userRef.child(firebaseAuth.currentUser!.uid).update({
                  "name": nameTextEditingController.text,
                }).then((value) {
                  nameTextEditingController.clear();
                  Fluttertoast.showToast(msg: "Driver name updated successfully");
                }).catchError((error) {
                  Fluttertoast.showToast(msg: "Error updating driver name");
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showDriverPhoneDialogAlert(BuildContext context, String phone) async {
    phoneTextEditingController.text = phone;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Driver Phone"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: phoneTextEditingController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                userRef.child(firebaseAuth.currentUser!.uid).update({
                  "phone": phoneTextEditingController.text,
                }).then((value) {
                  phoneTextEditingController.clear();
                  Fluttertoast.showToast(msg: "Driver phone updated successfully");
                }).catchError((error) {
                  Fluttertoast.showToast(msg: "Error updating driver phone");
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showDriverAddressDialogAlert(BuildContext context, String address) async {
    addressTextEditingController.text = address;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Driver Address"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: addressTextEditingController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                userRef.child(firebaseAuth.currentUser!.uid).update({
                  "address": addressTextEditingController.text,
                }).then((value) {
                  addressTextEditingController.clear();
                  Fluttertoast.showToast(msg: "Driver address updated successfully");
                }).catchError((error) {
                  Fluttertoast.showToast(msg: "Error updating driver address");
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: darkTheme ? Colors.amber.shade400 : Colors.black,
            ),
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              color: darkTheme ? Colors.amber.shade400 : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: ListView(
          padding: EdgeInsets.all(8),
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 50),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(50),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: darkTheme ? Colors.black : Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${onlineDriverData.name}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDriverNameDialogAlert(context, onlineDriverData.name!);
                          },
                          icon: Icon(
                            Icons.edit,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${onlineDriverData.phone!}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDriverPhoneDialogAlert(context, onlineDriverData.phone!);
                          },
                          icon: Icon(
                            Icons.edit,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${onlineDriverData.address!}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDriverAddressDialogAlert(context, onlineDriverData.address!);
                          },
                          icon: Icon(
                            Icons.edit,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: 1),
                    Text(
                      "${onlineDriverData.email!}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${onlineDriverData.car_model!}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                        ),
                        Image.asset(
                          onlineDriverData.car_type == "Car"
                              ? "assets/images/img_7.png"
                              : onlineDriverData.car_type == "Bike"
                              ? "assets/images/img_9.png"
                              : "assets/images/img_8.png",
                          scale: 2,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        firebaseAuth.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplashScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: Text("Log Out"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
