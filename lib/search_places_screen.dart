import 'package:flutter/material.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FutureScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: darkTheme ? Colors.black : Colors.white,),
        ),
          title: Text(
            "Search & Set dropoff location",
            style: TextStyle(darkTheme ? Colors.black : Colors.white,),
          ),
          elevation: 0.0,
      ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(),
            )
          ]
        )
    );
  }
}

