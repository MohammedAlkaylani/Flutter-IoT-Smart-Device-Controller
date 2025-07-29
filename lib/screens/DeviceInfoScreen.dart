import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/cubit/app_cubit.dart';
import 'package:myapp/cubit/app_states.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({Key? key}) : super(key: key);

  String getValueFromDeviceInfo(String deviceInfo, String key, String fallback) {
    if (!deviceInfo.contains('$key:')) return fallback;
    try {
      final parts = deviceInfo.split('$key: ');
      if (parts.length > 1) {
        return parts[1].split('\n')[0].trim();
      }
    } catch (e) {
      debugPrint('Error parsing $key: $e');
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Device Information"),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AppCubit>().fetchDeviceInfo(),
            ),
          ],
        ),
        body: BlocConsumer<AppCubit, AppStates>(
          listener: (context, state) {
            if (state is DeviceInfoErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to load device information'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<AppCubit>();
            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  _buildInfoCard(
                    context,
                    title: 'Power Statistics',
                    icon: Icons.power,
                    iconColor: Colors.blue,
                    children: [
                      _InfoTile(
                        title: "Plugged in Count",
                        value: cubit.parseDeviceInfo(cubit.deviceInfo, 'pluggedIn', "N/A"),
                        icon: Icons.power,
                        iconColor: Colors.blue,
                      ),
                      _InfoTile(
                        title: "Turned On Count",
                        value: cubit.parseDeviceInfo(cubit.deviceInfo, 'turnedOn', "N/A"),
                        icon: Icons.power_settings_new,
                        iconColor: Colors.green,
                      ),
                      _InfoTile(
                        title: "Total Usage Time",
                        value: _formatDuration(cubit.parseDeviceInfo(cubit.deviceInfo, 'secondsOnCN', "0")),
                        icon: Icons.timer,
                        iconColor: Colors.orange,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildInfoCard(
                    context,
                    title: 'Energy Usage',
                    icon: Icons.bolt,
                    iconColor: Colors.amber,
                    children: [
                      _InfoTile(
                        title: "All Time Energy",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'allTimeWS', "0")} Ws",
                        icon: Icons.bolt,
                        iconColor: Colors.amber,
                      ),
                      _InfoTile(
                        title: "Session Energy",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'sessionWS', "0")} Ws",
                        icon: Icons.energy_savings_leaf,
                        iconColor: Colors.lightGreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildInfoCard(
                    context,
                    title: 'Temperature Monitoring',
                    icon: Icons.thermostat,
                    iconColor: Colors.red,
                    children: [
                      _InfoTile(
                        title: "Component A Max Temp",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'componentAMax', "0")}°C",
                        icon: Icons.thermostat,
                        iconColor: Colors.red,
                      ),
                      _InfoTile(
                        title: "Component B Max Temp",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'componentBMax', "0")}°C",
                        icon: Icons.thermostat,
                        iconColor: Colors.deepOrange,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildInfoCard(
                    context,
                    title: 'Current Status',
                    icon: Icons.settings_input_component,
                    iconColor: Colors.purple,
                    children: [
                      _InfoTile(
                        title: "Voltage",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'voltage', "0")} V",
                        icon: Icons.flash_on,
                        iconColor: Colors.purple,
                      ),
                      _InfoTile(
                        title: "Power",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'power', "0")} W",
                        icon: Icons.electrical_services,
                        iconColor: Colors.blue,
                      ),
                      _InfoTile(
                        title: "Sensor A Temp",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'sensorA', "0")}°C",
                        icon: Icons.sensors,
                        iconColor: Colors.teal,
                      ),
                      _InfoTile(
                        title: "Sensor B Temp",
                        value: "${cubit.parseDeviceInfo(cubit.deviceInfo, 'sensorB', "0")}°C",
                        icon: Icons.memory,
                        iconColor: Colors.indigo,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildInfoCard(
                    context,
                    title: 'System Status',
                    icon: Icons.warning,
                    iconColor: cubit.parseDeviceInfo(cubit.deviceInfo, 'error', "No errors") == "No errors"
                        ? Colors.green
                        : Colors.red,
                    children: [
                      _InfoTile(
                        title: "Error Code",
                        value: cubit.parseDeviceInfo(cubit.deviceInfo, 'error', "No errors"),
                        icon: Icons.warning,
                        iconColor: cubit.parseDeviceInfo(cubit.deviceInfo, 'error', "No errors") == "No errors"
                            ? Colors.green
                            : Colors.red,
                      ),
                      _InfoTile(
                        title: "Last Error Code",
                        value: cubit.parseDeviceInfo(cubit.deviceInfo, 'lastError', "No errors"),
                        icon: Icons.error_outline,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatDuration(String seconds) {
    try {
      final totalSeconds = int.parse(seconds);
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final remainingSeconds = totalSeconds % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m ${remainingSeconds}s';
      } else if (minutes > 0) {
        return '${minutes}m ${remainingSeconds}s';
      } else {
        return '${remainingSeconds}s';
      }
    } catch (e) {
      return seconds;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 375;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 18 : 20,
            color: iconColor,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}