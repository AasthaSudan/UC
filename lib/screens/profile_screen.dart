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


// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 800),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool darkTheme = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Animated App Bar with gradient
//           SliverAppBar(
//             expandedHeight: 200,
//             floating: false,
//             pinned: true,
//             backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
//             leading: IconButton(
//               icon: Icon(
//                 Icons.arrow_back,
//                 color: darkTheme ? Colors.black : Colors.white,
//               ),
//               onPressed: () => Navigator.pop(context),
//             ),
//             flexibleSpace: FlexibleSpaceBar(
//               centerTitle: true,
//               title: Text(
//                 "My Profile",
//                 style: TextStyle(
//                   color: darkTheme ? Colors.black : Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                 ),
//               ),
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: darkTheme
//                         ? [Colors.amber.shade400, Colors.amber.shade700]
//                         : [Colors.blue.shade400, Colors.blue.shade700],
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     // Decorative circles
//                     Positioned(
//                       top: -50,
//                       right: -50,
//                       child: Container(
//                         width: 150,
//                         height: 150,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white.withOpacity(0.1),
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       bottom: -30,
//                       left: -30,
//                       child: Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white.withOpacity(0.1),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // Content
//           SliverToBoxAdapter(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child: Padding(
//                   padding: EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       // Profile Picture with animation
//                       Hero(
//                         tag: 'profile-avatar',
//                         child: Container(
//                           width: 140,
//                           height: 140,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: darkTheme
//                                   ? [Colors.amber.shade300, Colors.amber.shade600]
//                                   : [Colors.blue.shade300, Colors.blue.shade600],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: (darkTheme ? Colors.amber : Colors.blue).withOpacity(0.4),
//                                 blurRadius: 20,
//                                 spreadRadius: 5,
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Container(
//                               width: 130,
//                               height: 130,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: darkTheme ? Colors.grey.shade900 : Colors.white,
//                               ),
//                               child: Icon(
//                                 Icons.person,
//                                 size: 70,
//                                 color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//
//                       Text(
//                         userModelCurrentInfo?.name ?? userName,
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: darkTheme ? Colors.white : Colors.black,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.email_outlined,
//                             size: 16,
//                             color: Colors.grey,
//                           ),
//                           SizedBox(width: 5),
//                           Text(
//                             userModelCurrentInfo?.email ?? userEmail,
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: (darkTheme ? Colors.amber : Colors.blue).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.verified_user,
//                               size: 16,
//                               color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                             ),
//                             SizedBox(width: 5),
//                             Text(
//                               "Verified Member",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 30),
//
//                       // Stats Cards
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               icon: Icons.directions_car,
//                               title: "Rides",
//                               value: "0",
//                               darkTheme: darkTheme,
//                             ),
//                           ),
//                           SizedBox(width: 15),
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               icon: Icons.star,
//                               title: "Rating",
//                               value: "5.0",
//                               darkTheme: darkTheme,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 30),
//
//                       // Section Header
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "Account Settings",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: darkTheme ? Colors.white : Colors.black,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 15),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.person_outline,
//                         title: "Edit Profile",
//                         subtitle: "Update your personal information",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Edit Profile - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.history,
//                         title: "Ride History",
//                         subtitle: "View your past rides",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Ride History - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.payment,
//                         title: "Payment Methods",
//                         subtitle: "Manage your payment options",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Payment Methods - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.notifications_outlined,
//                         title: "Notifications",
//                         subtitle: "Configure notification preferences",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Notifications - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       SizedBox(height: 20),
//
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "More",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: darkTheme ? Colors.white : Colors.black,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 15),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.help_outline,
//                         title: "Help & Support",
//                         subtitle: "Get help and contact us",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Help & Support - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.settings_outlined,
//                         title: "Settings",
//                         subtitle: "App preferences and more",
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text("Settings - Coming Soon"),
//                               backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
//                             ),
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       _buildProfileOption(
//                         context,
//                         icon: Icons.info_outline,
//                         title: "About Trippo",
//                         subtitle: "Version 1.0.0",
//                         onTap: () {
//                           showAboutDialog(
//                             context: context,
//                             applicationName: "Trippo",
//                             applicationVersion: "1.0.0",
//                             applicationIcon: Icon(
//                               Icons.local_taxi,
//                               size: 50,
//                               color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                             ),
//                             children: [
//                               Text("A modern ride-sharing app for India"),
//                               SizedBox(height: 10),
//                               Text("Built with Flutter & Firebase"),
//                             ],
//                           );
//                         },
//                         darkTheme: darkTheme,
//                       ),
//
//                       SizedBox(height: 30),
//
//                       Container(
//                         width: double.infinity,
//                         height: 55,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.red.shade400, Colors.red.shade700],
//                           ),
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.red.withOpacity(0.3),
//                               blurRadius: 10,
//                               offset: Offset(0, 5),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: () => _showLogoutDialog(context),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             shadowColor: Colors.transparent,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.logout, color: Colors.white, size: 22),
//                               SizedBox(width: 10),
//                               Text(
//                                 "Logout",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(
//       BuildContext context, {
//         required IconData icon,
//         required String title,
//         required String value,
//         required bool darkTheme,
//       }) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: darkTheme
//               ? [Colors.grey.shade900, Colors.grey.shade800]
//               : [Colors.white, Colors.grey.shade50],
//         ),
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: (darkTheme ? Colors.amber : Colors.blue).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               size: 28,
//               color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//             ),
//           ),
//           SizedBox(height: 12),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: darkTheme ? Colors.white : Colors.black,
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProfileOption(
//       BuildContext context, {
//         required IconData icon,
//         required String title,
//         required String subtitle,
//         required VoidCallback onTap,
//         required bool darkTheme,
//       }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: darkTheme ? Colors.grey.shade900 : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(15),
//           child: Padding(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: (darkTheme ? Colors.amber : Colors.blue).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                     size: 24,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: darkTheme ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   size: 16,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     bool darkTheme = Theme.of(context).brightness == Brightness.dark;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: Row(
//           children: [
//             Icon(
//               Icons.logout,
//               color: Colors.red,
//             ),
//             SizedBox(width: 10),
//             Text("Logout"),
//           ],
//         ),
//         content: Text(
//           "Are you sure you want to logout from your account?",
//           style: TextStyle(fontSize: 16),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "Cancel",
//               style: TextStyle(
//                 color: darkTheme ? Colors.amber.shade400 : Colors.blue,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await firebaseAuth.signOut();
//               Navigator.pop(context); // Close dialog
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => LoginScreen(),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text(
//               "Logout",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }