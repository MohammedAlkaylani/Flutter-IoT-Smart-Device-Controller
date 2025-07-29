import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/services/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "REGISTER",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: textScaleFactor * 22,
            color: const Color(0xFF1E232C),
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset(
            'assets/back_icon.png', // Changed from 'back.png'
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
            SizedBox(height: size.height * 0.03),
            RichText(
              text: const TextSpan(
                text: 'LOGO', // Changed from
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
            _buildTextField(
              context: context,
              controller: usernameController,
              label: 'User Name',
              icon: Icons.person_outline,
              hintText: 'Enter your username',
            ),
            SizedBox(height: size.height * 0.025),
            _buildTextField(
              context: context,
              controller: emailController,
              label: 'Email',
              icon: Icons.mail_outline,
              hintText: 'Enter your email',
            ),
            SizedBox(height: size.height * 0.025),
            _buildPasswordField(
              context: context,
              controller: passwordController,
              label: 'Password',
              hintText: 'Enter your password',
            ),
            SizedBox(height: size.height * 0.025),
            _buildPasswordField(
              context: context,
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
            ),
            SizedBox(height: size.height * 0.04),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 50 : 56,
              child: ElevatedButton(
                onPressed: () => _handleRegistration(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Register',
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
                    'Or Register with',
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
                  iconPath: 'assets/social_facebook.png', // Changed
                  onPressed: () {},
                ),
                SizedBox(width: size.width * 0.04),
                _buildSocialButton(
                  context,
                  iconPath: 'assets/social_google.png', // Changed
                  onPressed: () {},
                ),
                SizedBox(width: size.width * 0.04),
                _buildSocialButton(
                  context,
                  iconPath: 'assets/social_apple.png', // Changed
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: size.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Login Now",
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

  Future<void> _handleRegistration(BuildContext context) async {
    final username = usernameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validate inputs
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      // Call registration service
      final result = await AuthService().registerUser(
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E232C),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        TextField(
          controller: controller,
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
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF8391A1)),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E232C),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E232C),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        TextField(
          controller: controller,
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
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF8391A1)),
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            suffixIcon: IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Colors.grey),
              onPressed: () {},
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E232C),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, {
    required String iconPath,
    required VoidCallback onPressed,
  }) {
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