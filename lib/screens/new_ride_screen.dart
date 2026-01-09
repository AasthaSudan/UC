import 'package:flutter/material.dart';

class NewRideScreen extends StatelessWidget {
  const NewRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Ride"),
      ),
      body: const Center(
        child: Text(
          "Ride Accepted",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
