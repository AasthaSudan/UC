import 'package:flutter/material.dart';

class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      color: darkTheme?Colors.amberAccent:Colors.lightBlueAccent,
      child: Column(
        children: [
          Container(
          color:darkTheme?Colors.black:Colors.lightBlue,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                Text(
                "Total Earnings",
                style: TextStyle(
                  fontSize: 16,
                  color: darkTheme?Colors.amber.shade400:Colors.white;
                ),
            ),

            const SizedBox(height: 10),

            Text(
              " " + Provider.of<AppInfo>(context, listen:false).driverTotalEarnings,
              style: TextStyle(
                fontSize: 60,
                color: darkTheme?Colors.amber.shade400:Colors.white;
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
       ),
      ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TripsHistoryScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white54,
            ),

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Image.asset(
                    onlineDriverData.car_type=="Car" ? "assets/images/img_7.png"
                        : onlineDriverData.car_type=="CNG" ? "assets/images/img_8.png"
                        : "assets/images/img_9.png",
                    scale: 2,

                    Text(
                      "Trips Completed",
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),

                    Expanded(
                      child: Continer(
                        child: Text(
                          Provider.of<AppInfo>(context, listen:false).allTripsHistoryInfo.length.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
