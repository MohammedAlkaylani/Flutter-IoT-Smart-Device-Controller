import 'package:flutter/material.dart';
import 'package:myapp/screens/auth/login_screen.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/success_icon.png',  // Changed from 'correct.png'
              width: 200,  // Adjusted to more standard size
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Password Changed!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your password has been changed successfully.',
              style: TextStyle(
                fontSize: 16,  // Slightly larger for better readability
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,  // Responsive width
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(  // Changed to pushReplacement
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: 18,  // Slightly smaller for better fit
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}