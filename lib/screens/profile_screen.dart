import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global/global.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
        title: Text(
          "Profile",
          style: TextStyle(
            color: darkTheme ? Colors.black : Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: darkTheme ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    border: Border.all(
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: darkTheme ? Colors.black : Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // User Name
              Text(
                userModelCurrentInfo?.name ?? userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 5),

              // User Email
              Text(
                userModelCurrentInfo?.email ?? userEmail,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 30),

              // Profile Options
              _buildProfileOption(
                context,
                icon: Icons.person_outline,
                title: "Edit Profile",
                onTap: () {
                  // TODO: Navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Edit Profile - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              _buildProfileOption(
                context,
                icon: Icons.history,
                title: "Ride History",
                onTap: () {
                  // TODO: Navigate to ride history screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ride History - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              _buildProfileOption(
                context,
                icon: Icons.payment,
                title: "Payment Methods",
                onTap: () {
                  // TODO: Navigate to payment methods screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Payment Methods - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              _buildProfileOption(
                context,
                icon: Icons.notifications_outlined,
                title: "Notifications",
                onTap: () {
                  // TODO: Navigate to notifications screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Notifications - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              _buildProfileOption(
                context,
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () {
                  // TODO: Navigate to help & support screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Help & Support - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              _buildProfileOption(
                context,
                icon: Icons.settings_outlined,
                title: "Settings",
                onTap: () {
                  // TODO: Navigate to settings screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Settings - Coming Soon")),
                  );
                },
                darkTheme: darkTheme,
              ),

              SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Logout"),
                        content: Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await firebaseAuth.signOut();
                              Navigator.pop(context); // Close dialog
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        required bool darkTheme,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkTheme ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}