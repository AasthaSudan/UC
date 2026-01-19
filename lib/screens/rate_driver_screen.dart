// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:smooth_star_rating/smooth_star_rating.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'screens/splash_screen.dart';
// import 'global/global.dart';
//
// class RateDriverScreen extends StatefulWidget {
//   String? assignedDriverId;
//   RateDriverScreen({this.assignedDriverId});
//
//   const RateDriverScreen({super.key});
//
//   @override
//   State<RateDriverScreen> createState() => _RateDriverScreenState();
// }
//
// class _RateDriverScreenState extends State<RateDriverScreen> {
//   @override
//   Widget build(BuildContext context) {
//     bool darkTheme=MediaQuery.of(context).platformBrightness==Brightness.dark;
//
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       backgroundColor: Colors.transparent,
//       child: Container(
//         margin: const EdgeInsets.all(8),
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           color: darkTheme?Colors.black:Colors.white,
//       ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 22),
//             const Text(
//               "Rate Trip Experience",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 2,
//                 color: darkTheme?Colors.amber.shade400:Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             Divider(
//               thickness: 2,
//               color: darkTheme?Colors.amber.shade400:Colors.blue,
//             ),
//
//             const SizedBox(height: 20),
//
//             SmoothStarRating(
//               rating: countRatingStars,
//               allowHalfRating: false;
//               starCount: 5,
//               color:darkTheme?Colors.amber.shade400:Colors.blue,
//               borderColor: darkTheme?Colors.amber.shade400:Colors.grey,
//               size: 46,
//               onRated: (value){
//                 countRatingStars=value;
//
//                 if(countRatingStars==1){
//                   setState(() {
//                     titleStarsRating="Very Bad";
//                   });
//                 }
//                 if(countRatingStars==2){
//                   setState(() {
//                     titleStarsRating="Not Good";
//                   });
//                 }
//                 if(countRatingStars==3){
//                   setState(() {
//                     titleStarsRating="Good";
//                   });
//                 }
//                 if(countRatingStars==4){
//                   setState(() {
//                     titleStarsRating="Very Good";
//                   });
//                 }
//                 if(countRatingStars==5){
//                   setState(() {
//                     titleStarsRating="Excellent";
//                   });
//                 },
//               },
//             ),
//
//             const SizedBox(height: 10),
//             Text(
//               titleStarsRating,
//               style: const TextStyle(
//                 fontSize: 30,
//                 fontWeight: FontWeight.bold,
//                 color: darkTheme?Colors.amber.shade400:Colors.blue,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             ElevatedButton(
//               onPressed: (){
//                 DatabaseReference ref=FirebaseDatabase.instance.ref()
//                     .child("drivers")
//                     .child(widget.assignedDriverId!)
//                     .child("ratings");
//
//                 ref.once().then((snap){
//                   if(snap.snapshot.value!=null){
//                     ref.set(countRatingStars.toString());
//                     Navigator.pop(context);
//                     Navigator.push(context, MaterialPageRoute(builder: (_)=>SplashScreen()));
//                   }
//                   else{
//                     double oldRating=double.parse(snap.snapshot.value.toString());
//                     double averageRating=(oldRating+countRatingStars)/2;
//                     ref.set(averageRating.toString());
//                     Navigator.pop(context);
//                     Navigator.push(context, MaterialPageRoute(builder: (_)=>SplashScreen()));
//                   }
//                   Fluttertoast.showToast(msg: "Rating submitted successfully");
//                 });
//               },
//               style: ElevatedButton.styleFrom(
//                 primary: darkTheme?Colors.amber.shade400:Colors.blue,
//                 padding: const EdgeInsets.symmetric(horizontal: 70),
//               ),
//
//               child: const Text(
//                 "Submit",
//                 style: TextStyle(
//                   color: darkTheme?Colors.black:Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
