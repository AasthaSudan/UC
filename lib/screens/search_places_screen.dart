import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../assistants/assistant_methods.dart';
import '../widgets/place_prediction_tile.dart';
import '../info/app_info.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  List<Map<String, dynamic>> placesPredictedList = [];
  bool isSearching = false;

  void findPlaceAutoCompleteSearch(String inputText) async {
    if (inputText.length > 2) {
      setState(() {
        isSearching = true;
      });

      var results = await AssistantMethods.searchPlaces(inputText);

      setState(() {
        placesPredictedList = results;
        isSearching = false;
      });
    } else {
      setState(() {
        placesPredictedList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          title: Text(
            "Search & Set Drop Off location",
            style: TextStyle(
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.adjust_sharp,
                          color: darkTheme ? Colors.black : Colors.white,
                        ),
                        SizedBox(width: 18.0),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                              onChanged: (value) {
                                findPlaceAutoCompleteSearch(value);
                              },
                              decoration: InputDecoration(
                                hintText: "Search Drop Off Location",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                fillColor: darkTheme ? Colors.black : Colors.white54,
                                filled: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  left: 10,
                                  top: 8,
                                  bottom: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isSearching)
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  darkTheme ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            (placesPredictedList.length > 0)
                ? Expanded(
              child: ListView.separated(
                itemCount: placesPredictedList.length,
                itemBuilder: (context, index) {
                  return PlacePredictionTileDesign(
                    predictedPlace: placesPredictedList[index],
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(
                    height: 0,
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    thickness: 0,
                  );
                },
              ),
            )
                : Container(
              padding: EdgeInsets.all(20),
              child: Text(
                placesPredictedList.isEmpty && !isSearching
                    ? "Start typing to search for places..."
                    : "",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}