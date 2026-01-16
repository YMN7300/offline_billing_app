import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/colors/colors.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.deepPurple,
        title: Text(
          "BILLERS",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 15, left: 15),

        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "log_in_page");
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(50, 50),
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // SizedBox(width: 10),
            // Expanded(
            //   child: ElevatedButton(
            //     onPressed: () {
            //       Navigator.pushNamed(context, "create_acc_page");
            //     },
            //     style: ElevatedButton.styleFrom(
            //       fixedSize: Size(50, 50),
            //       backgroundColor: primary,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //     ),
            //     child: Text(
            //       "Create Account",
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 17,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/homepage.png', height: 400, width: 400),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
                child: Text(
                  "Fast & Easy Invoice Generator", // Added text
                  style: TextStyle(
                    fontSize: 43,
                    fontWeight: FontWeight.bold,
                    color: primary,

                    decorationColor: primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
