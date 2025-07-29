import 'package:flutter/material.dart';
import 'package:myapp/main.dart';

class NewPasswordScreen extends StatefulWidget {
  final int userId;
  
  const NewPasswordScreen({super.key, required this.userId});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "",
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.04),
              Text(
                'Create new password',
                style: TextStyle(
                  fontSize: isSmallScreen ? 26 : 30,
                  color: const Color(0xFFF18000),
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              SizedBox(height: size.height * 0.05),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              TextField(
                controller: _newPasswordController,
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
                  labelText: 'New Password',
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
              SizedBox(height: size.height * 0.025),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1E232C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              TextField(
                controller: _confirmPasswordController,
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
                  labelText: 'Confirm New Password',
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
              if (_errorMessage != null)
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              SizedBox(height: size.height * 0.05),
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 50 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
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
                          'Reset Password',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate password reset API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to update password');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}