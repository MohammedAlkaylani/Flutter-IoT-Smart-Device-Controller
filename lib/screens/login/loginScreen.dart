import 'package:flutter/material.dart';
import 'package:myapp/cubit/app_cubit.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/auth/forgot_password_screen.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/services/app_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "LOG IN",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: textScaleFactor * 22,
            color: const Color(0xFF1E232C),
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset(
            'assets/back_icon.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.02,
        ),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.04),
            RichText(
              text: const TextSpan(
                text: 'My',
                style: TextStyle(
                  fontSize: 30,
                  color: Color(0xFFF18000),
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: ' Account',
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFFF18000),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.05),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSmallScreen ? 14 : 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF18000)),
                ),
                hintText: 'Enter your Email',
                hintStyle: const TextStyle(color: Color(0xFF8391A1)),
                prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF7F8F9),
              ),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E232C),
              ),
            ),
            SizedBox(height: size.height * 0.025),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSmallScreen ? 14 : 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF18000)),
                ),
                hintText: 'Enter your password',
                hintStyle: const TextStyle(color: Color(0xFF8391A1)),
                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF7F8F9),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E232C),
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF18000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 50 : 56,
              child: ElevatedButton(
                onPressed: () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Login',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: size.height * 0.05),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey[400],
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Or Login with',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey[400],
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  context,
                  iconPath: 'assets/social_facebook.png',
                  onPressed: () {},
                ),
                SizedBox(width: size.width * 0.04),
                _buildSocialButton(
                  context,
                  iconPath: 'assets/social_google.png',
                  onPressed: () {},
                ),
                SizedBox(width: size.width * 0.04),
                _buildSocialButton(
                  context,
                  iconPath: 'assets/social_apple.png',
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: size.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Register Now",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF18000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AppServices.loginUser(_emailController.text);
      
      if (response['success'] == true) {
        final user = response['user'];
        if (AppServices.verifyPassword(
          user['PasswordHash'],
          user['Salt'],
          _passwordController.text,
        )) {
          await AppServices.saveUserData(user);
          final cubit = AppCubit.get(context);
          await cubit.updateUserID(user['UserID']);
          await cubit.initializeUserData();
          await AppServices.updateLastLogin(user['UserID']);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton(BuildContext context,
      {required String iconPath, required VoidCallback onPressed}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.18,
      height: size.width * 0.18,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFE8ECF4),
              width: 1,
            ),
          ),
          elevation: 0,
        ),
        child: Image.asset(
          iconPath,
          width: size.width * 0.08,
          height: size.width * 0.08,
        ),
      ),
    );
  }
}