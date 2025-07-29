import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/cubit/app_cubit.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/app_services.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _uploadProfilePicture(File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final cubit = context.read<AppCubit>();
    final userId = cubit.userID;
    if (userId == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final result = await Provider.of<AppServices>(context, listen: false)
          .uploadProfilePicture(
        userId: userId,
        imageFile: imageFile,
      );
      
      if (result['success'] == true) {
        cubit.profilePicture = imageFile;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to upload picture')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading picture: ${e.toString()}')),
      );
    }
  }

  void _showPasswordDialog() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: isSmallScreen ? 5 : 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF18000)),
                ),
                hintText: 'Old Password',
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
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: isSmallScreen ? 5 : 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF18000)),
                ),
                hintText: 'New Password',
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
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: isSmallScreen ? 5 : 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF18000)),
                ),
                hintText: 'Confirm New Password',
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
            SizedBox(height: size.height * 0.02),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final oldPassword = oldPasswordController.text;
                  final newPassword = newPasswordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  final cubit = context.read<AppCubit>();
                  final userId = cubit.userID;

                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User not authenticated')),
                    );
                    return;
                  }

                  final result = await Provider.of<AppServices>(context, listen: false)
                      .changePassword(
                        userId: userId,
                        oldPassword: oldPassword,
                        newPassword: newPassword,
                        confirmPassword: confirmPassword,
                      );

                  if (result['success'] == true) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password changed successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Failed to change password')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF7F8F9),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.deepOrange),
                  ),
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: context.watch<AppCubit>().profilePicture != null
                        ? Image.file(
                            context.watch<AppCubit>().profilePicture!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/default_profile.png',
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/default_profile.png',
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: _showImageSourceDialog,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'John Doe',
              style: theme.textTheme.headline6?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'user@example.com',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: _showPasswordDialog,
            ),
            _buildProfileOption(
              icon: Icons.notifications_outlined,
              title: 'Notification Settings',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF7F8F9),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.deepOrange),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 8),
    );
  }
}