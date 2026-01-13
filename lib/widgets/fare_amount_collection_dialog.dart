import 'package:flutter/material.dart';
import 'splash_screen.dart';

class FareAmountCollectionDialog extends StatefulWidget {
  final double totalFareAmount;

  const FareAmountCollectionDialog({
    super.key,
    required this.totalFareAmount,
  });

  @override
  State<FareAmountCollectionDialog> createState() =>
      _FareAmountCollectionDialogState();
}

class _FareAmountCollectionDialogState
    extends State<FareAmountCollectionDialog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(6),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),

            Text(
              "Trip Fare Amount",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.black,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "₹${widget.totalFareAmount.toStringAsFixed(2)}",
              style: TextStyle(
                color: darkTheme ? Colors.amber.shade400 : Colors.black,
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Text(
                "This is the total trip amount. Please collect it from the user.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkTheme ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  darkTheme ? Colors.amber.shade400 : Colors.blue,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);

                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SplashScreen(),
                      ),
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Collect Cash",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "₹${widget.totalFareAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
