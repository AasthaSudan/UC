import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/predicted_places.dart';
import '../models/directions.dart';
import '../info/app_info.dart';
import '../global/global.dart';

class PlacePredictionTileDesign extends StatefulWidget {
  final Map<String, dynamic> predictedPlace;

  const PlacePredictionTileDesign({Key? key, required this.predictedPlace}) : super(key: key);

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {

  void setDropOffLocation(BuildContext context) {
    String placeName = widget.predictedPlace['display_name'] ?? '';
    double lat = double.parse(widget.predictedPlace['lat'] ?? '0');
    double lon = double.parse(widget.predictedPlace['lon'] ?? '0');
    String placeId = widget.predictedPlace['place_id']?.toString() ?? '';

    Directions directions = Directions();
    directions.locationName = placeName;
    directions.locationId = placeId;
    directions.locationLatitude = lat;
    directions.locationLongitude = lon;

    Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

    Navigator.pop(context, "obtainDirectionResponse");
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    String displayName = widget.predictedPlace['display_name'] ?? '';
    List<String> parts = displayName.split(',');
    String mainText = parts.isNotEmpty ? parts[0] : displayName;
    String secondaryText = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return ElevatedButton(
      onPressed: () {
        setDropOffLocation(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
        padding: EdgeInsets.zero,
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.add_location,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              size: 28,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),
                  if (secondaryText.isNotEmpty) ...[
                    SizedBox(height: 3),
                    Text(
                      secondaryText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}