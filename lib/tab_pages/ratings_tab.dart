import 'package:flutter/material.dart';

class RatingsTab extends StatefulWidget {
  const RatingsTab({super.key});

  @override
  State<RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends State<RatingsTab> {
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
  }

  getRatingsNumber() {
    setState(() {
      rating=double.parse(Provider.of<AppInfo>(context, listen:false).driverAverageRatings);
    });

    setupRatingsTitle();
  }

  setupRatingsTitle() {
    if(rating>=0) {
      setState(() {
        titleStarsRating="Very Bad";
      });
    }
    else if(rating>=1) {
      setState(() {
        titleStarsRating="Bad";
      });
    }
    else if(rating>=2) {
      setState(() {
        titleStarsRating="Good";
      });
    }
    else if(rating>=3) {
      setState(() {
        titleStarsRating="Very Good";
      });
    }
    else if(rating>=4) {
      setState(() {
        titleStarsRating="Excellent";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme=MediaQuery.of(context).platformBrightness==Brightness.dark;

    return Scaffold(
      backgroundColor: darkTheme?Colors.black:Colors.white,
      body: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: darkTheme?Colors.grey:Colors.white60,
        child: Container(
          margin: const EdgeInsets.all(4),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: darkTheme?Colors.black:Colors.white54,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 22),

              Text(
                "Your Ratings",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: darkTheme?Colors.amber.shade400:Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              SmoothStarRating(
                rating: rating,
                allowHalfRating: true,
                starCount: 5,
                color: darkTheme?Colors.amber.shade400:Colors.blue,
                borderColor: darkTheme?Colors.amber.shade400:Colors.blue,
                size: 46,
              ),

              SizedBox(height: 12),

              Text(
                titleStarsRating,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkTheme?Colors.amber.shade400:Colors.blue,
                ),
              ),

              const SizedBox(height: 10),

            ],
          ),
        ),
      ),
    );
  }
}
