import 'package:flutter/material.dart';

import '../common/components/colors/colors.dart';
import '../common/components/custom_files/custom_text_field.dart';

class LogInPage extends StatelessWidget {
  const LogInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 130, right: 35, left: 35),
            child: Column(
              children: [
                Text(
                  "Login here",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Text(
                  "Welcome",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 50),
                // Email Field
                CustomTextField(
                  labelText: "Email",
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // Password Field
                CustomTextField(
                  labelText: "Password",
                  controller: passwordController,
                  obscureText: true,
                ),
                // TextButton(
                //   onPressed: () {
                //     Navigator.pushNamed(context, "forgot_password_page");
                //   },
                //   child: Align(
                //     alignment: Alignment.centerRight,
                //     child: Text(
                //       "Forgot Password",
                //       style: TextStyle(
                //         color: primary,
                //         fontSize: 14.0,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email == "admin" && password == "admin") {
                      Navigator.pushReplacementNamed(
                        context,
                        "bottom_navigation_page",
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Email or password is incorrect"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(320, 50),
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Sign in",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // TextButton(
                //   onPressed: () {
                //     Navigator.pushNamed(context, "create_acc_page");
                //   },
                //   child: Align(
                //     alignment: Alignment.center,
                //     child: Text(
                //       "Don't have Account? Create Here",
                //       style: TextStyle(
                //         color: primary,
                //         fontSize: 14,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
