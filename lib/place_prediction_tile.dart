import 'package:flutter/material.dart';
import 'package:predicted_places.dart';

class PlacePredictionTileDesign extends StatefulWidget {
  const PlacePredictionTileDesign({this.predictedPlaces});

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {

  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Setting Drop Off, Please wait...",),
    )
    );
var responseApi=await RequestAssistant.receiveRequest(
    "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey");
      Navigator.pop(context);

      if(responseApi == "Error Occurred. Failed. No Response."){
        return;
    }

      if(responseApi["status"] == "OK"){
        Directions directions=Directions();
        directions.locationName=responseApi["result"]["name"];
        directions.locationId=placeId;
        directions.locationLatitude=responseApi["result"]["geometry"]["location"]["lat"];
        directions.locationLongitude=responseApi["result"]["geometry"]["location"]["lng"];

        Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

        setState(() {
          userDropOffLocation=directions.locationName;
    })
      }

  }
  @override
  Widget build(BuildContext context) {
    bool darkTheme=MediaQuery.of(context).platformBrightness==Brightness.dark;
    return ElevatedButton(

      onPressed: () {
        getPlaceDirectionDetails(widget.predictedPlaces!.placeId, context);
      },

      style: ElevatedButton.styleFrom(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
    );
  }
}
