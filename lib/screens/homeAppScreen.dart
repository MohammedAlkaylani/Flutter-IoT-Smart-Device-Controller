import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/cubit/auth_cubit.dart';
import 'package:myapp/cubit/auth_state.dart';
import 'package:myapp/screens/device/bluetooth_config_screen.dart';
import 'package:myapp/screens/device/device_control_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/services/device_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _userDevices = [];
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
    _loadUserDevices();
  }

  Future<void> _loadUserDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final cubit = AuthCubit.get(context);
      _userDevices = await DeviceService.getUserDevices(cubit.userId);
    } catch (e) {
      debugPrint('Error loading devices: $e');
    } finally {
      setState(() => _loadingDevices = false);
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserDevices(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://your-api-endpoint.com/api/devices/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['devices'] != null) {
          return List<Map<String, dynamic>>.from(data['devices']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      return [];
    }
  }

  Future<void> _refreshUserData() async {
    final cubit = AuthCubit.get(context);
    await cubit.refreshUserData();
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Image.asset(
          device['deviceType'] == 'Smart Cooker'
              ? 'assets/device_cooker.png'
              : 'assets/device_fan.png',
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
        ),
        title: Text(
          device['deviceName'] ?? 'Unknown Device',
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        subtitle: Text(
          device['deviceAddress'],
          style: TextStyle(fontSize: screenWidth * 0.035),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final cubit = AuthCubit.get(context);
          cubit.setActiveDevice(
            device['deviceId'].toString(),
            device['deviceAddress'],
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceControlScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AuthCubit.get(context);
    final size = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final deviceService = Provider.of<DeviceService>(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is UserDataError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is UserDataLoading || _loadingDevices) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: false,
            titleSpacing: size.width * 0.05,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: CircleAvatar(
                    radius: size.width * 0.045,
                    backgroundImage: _getProfileImage(cubit, deviceService),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    ).then((_) => _refreshUserData());
                  },
                ),
                SizedBox(width: size.width * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Home,",
                      style: TextStyle(
                        fontSize: textScaleFactor * 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      cubit.username.isNotEmpty ? cubit.username : "Guest",
                      style: TextStyle(
                        fontSize: textScaleFactor * 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications,
                      size: size.width * 0.08, color: Colors.grey[700]),
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BluetoothConfigScreen()),
                    );
                  },
                  icon: Icon(Icons.add,
                      size: size.width * 0.08, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          body: _loadingDevices
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _refreshUserData();
                    await _loadUserDevices();
                  },
                  child: _userDevices.isEmpty
                      ? const Center(child: Text("No devices found"))
                      : ListView.builder(
                          itemCount: _userDevices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(
                              Map<String, dynamic>.from(_userDevices[index]),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }

  ImageProvider _getProfileImage(AuthCubit cubit, DeviceService deviceService) {
    if (cubit.userProfilePicture != null) {
      return NetworkImage(cubit.userProfilePicture!);
    } else if (deviceService.profilePicture != null) {
      return FileImage(deviceService.profilePicture!);
    }
    return const AssetImage('assets/default_profile.png');
  }
}