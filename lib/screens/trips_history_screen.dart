// import 'package:flutter/material.dart';
//
// class TripHistoryScreen extends StatefulWidget {
//   const TripHistoryScreen({super.key});
//
//   @override
//   State<TripHistoryScreen> createState() => _TripHistoryScreenState();
// }
//
// class _TripHistoryScreenState extends State<TripHistoryScreen> {
//
//   bool darkTheme=MediaQuery.of(context).platformBrightness==Brightness.dark;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scffold(
//       backgroundColor: darkTheme?Colors.black:Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: darkTheme?Colors.black:Colors.white,
//         title: Text(
//           "Trip History",
//           style: TextStyle(
//             color: darkTheme?Colors.amber.shade400:Colors.black,
//           ),
//         ),
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon: Icon(
//             Icons.close,
//             color: darkTheme?Colors.amber.shade400:Colors.black,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: ListView.separated(
//           itemBuilder: (context, index) {
//             return Card(
//               color:Colors.grey[100];
//               shadowColor: Colors.transparent,
//               child: HistoryDesignUIWidget(
//                 tripHistoryModel: Provider.of<AppInfo>(context).tripHistoryList[index],
//               ),
//             ),
//           },
//
//           separatorBuilder: (context, index) => const SizedBox(height: 10),
//           itemCount: Provider.of<AppInfo>(context).tripHistoryList.length,
//           physics: ClampingScrollPhysics(),
//           shrinkWrap: true,
//         ),
//       ),
//     );
//   }
// }
