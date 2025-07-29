import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final size = MediaQuery.of(context).size;
    
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is DeviceCommandSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Command sent successfully')),
          );
        } else if (state is DeviceCommandError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final cubit = BlocProvider.of<AppCubit>(context);
        if (cubit.userID == null || cubit.deviceID == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Device information not available')),
          );
        }
        
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: false,
            titleSpacing: screenWidth * 0.05,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: CircleAvatar(
                    radius: size.width * 0.045,
                    backgroundImage: const AssetImage('assets/profile.png'),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
                SizedBox(width: screenWidth * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Home,",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "User",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Image.asset(
                    'assets/menu.png',
                    width: screenWidth * 0.05,
                    height: screenWidth * 0.05,
                  ),
                  onPressed: () => _showSettingDialog(context),
                )
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildDeviceInfoHeader(cubit, screenWidth),
                  SizedBox(height: screenHeight * 0.04),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    mainAxisSpacing: screenHeight * 0.02,
                    crossAxisSpacing: screenWidth * 0.03,
                    children: [
                      _buildControlButton(
                        context,
                        iconPath: 'assets/manual.png',
                        label: "Manual",
                        onPressed: () => _navigateToModeScreen(context, 'manual'),
                      ),
                      _buildControlButton(
                        context,
                        iconPath: 'assets/mode1.png',
                        label: "Mode 1",
                        onPressed: () => _navigateToModeScreen(context, 'mode1'),
                      ),
                      _buildControlButton(
                        context,
                        iconPath: 'assets/mode2.png',
                        label: "Mode 2",
                        onPressed: () => _navigateToModeScreen(context, 'mode2'),
                      ),
                      _buildControlButton(
                        context,
                        iconPath: 'assets/mode3.png',
                        label: "Mode 3",
                        onPressed: () => _navigateToModeScreen(context, 'mode3'),
                      ),
                      _buildControlButton(
                        context,
                        iconPath: 'assets/mode4.png',
                        label: "Mode 4",
                        onPressed: () => _navigateToModeScreen(context, 'mode4'),
                      ),
                      _buildControlButton(
                        context,
                        iconPath: 'assets/mode5.png',
                        label: "Mode 5",
                        onPressed: () => _navigateToModeScreen(context, 'mode5'),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  const Divider(),
                  SizedBox(height: size.height * 0.02),
                  _buildControlButtontwo(
                    context,
                    iconPath: 'assets/add.png',
                    label: "New Mode",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewModeScreen()),
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceInfoHeader(AppCubit cubit, double screenWidth) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Row(
          children: [
            const Icon(Icons.device_thermostat, color: Colors.orange),
            SizedBox(width: screenWidth * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Connected Device",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  cubit.deviceID ?? 'Unknown Device',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModeScreen(BuildContext context, String modeName) {
    final cubit = BlocProvider.of<AppCubit>(context);
    if (modeName == 'manual') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModeStartScreen(name: modeName),
        ),
      );
    } else {
      final settings = cubit.modeSettings[modeName] ?? {'power': 50, 'time': 1};
      cubit.sendModeCommand(
        mode: "power",
        name: cubit.stringToHex(modeName.replaceAll('_', ' ')),
        power: settings['power'] ?? 50,
        time: settings['time'] ?? 1,
      );
    }
  }

  Widget _buildControlButton(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        side: const BorderSide(
          color: Color(0xFF1E232C),
          width: 1.0,
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.all(screenWidth * 0.02),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtontwo(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        side: const BorderSide(
          color: Color(0xFF1E232C),
          width: 1.0,
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.all(screenWidth * 0.03),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
          ),
          SizedBox(width: screenWidth * 0.04),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsSection(
                context,
                title: "Settings",
                items: [
                  _SettingsItem(
                    icon: Icons.wifi,
                    title: "WiFi Information",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WifiInfoScreen()),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.system_update,
                    title: "Firmware Update",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OTAUpdateScreen()),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.info,
                    title: "Device Information",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeviceInfoScreen()),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.security,
                    title: "Legal Information",
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.access_time,
                    title: "Device Time Zone",
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.home,
                    title: "Add to Home Screen",
                    onTap: () {},
                  ),
                ],
              ),
            ]
          ),
        );
      },
    );
  }
}

Widget _buildSettingsSection(BuildContext context, {
  required String title,
  required List<Widget> items,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      ...items,
    ],
  );
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}