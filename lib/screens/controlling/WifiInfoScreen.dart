import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/cubit/app_cubit.dart';
import 'package:myapp/cubit/app_states.dart';

class WifiInfoScreen extends StatelessWidget {
  const WifiInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AppCubit>().fetchNetworkInfo(),
            ),
          ],
        ),
        body: BlocBuilder<AppCubit, AppStates>(
          buildWhen: (previous, current) => current is NetworkInfoUpdated,
          builder: (context, state) {
            final cubit = context.read<AppCubit>();
            final info = _parseNetworkInfo(cubit.networkInfo);
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Color(0xFFFFFFFF),
                    shadowColor: Colors.transparent,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoTile(
                            title: 'SSID',
                            value: info['ssid'] ?? 'Unknown',
                            icon: Icons.wifi,
                          ),
                          _InfoTile(
                            title: 'IP Address',
                            value: info['ip'] ?? '0.0.0.0',
                            icon: Icons.language,
                          ),
                          _InfoTile(
                            title: 'MAC Address',
                            value: info['mac'] ?? '00:00:00:00:00:00',
                            icon: Icons.device_hub,
                          ),
                          _InfoTile(
                            title: 'Channel',
                            value: info['channel'] ?? 'Unknown',
                            icon: Icons.tune,
                          ),
                          _InfoTile(
                            title: 'Security',
                            value: info['security'] ?? 'Unknown',
                            icon: Icons.security,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(String status) {
    final isConnected = status.toLowerCase().contains('connected');
    return Row(
      children: [
        Icon(
          isConnected ? Icons.check_circle : Icons.error,
          color: isConnected ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isConnected ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSignalStrength(String? signalStr) {
    if (signalStr == null) return const SizedBox();
    final signal = int.tryParse(signalStr.replaceAll('%', '')) ?? 0;
    Color color;
    if (signal > 70) color = Colors.green;
    else if (signal > 40) color = Colors.orange;
    else color = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signal Strength: $signalStr',
          style: TextStyle(color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: signal / 100,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildAdvancedInfoCard(BuildContext context, Map<String, String> info) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 375;

    return ExpansionTile(
      title: Text(
        'Advanced Information',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 12 : 16,
            right: isSmallScreen ? 12 : 16,
            bottom: isSmallScreen ? 12 : 16,
          ),
          child: Text(
            info['raw'] ?? 'No additional information available',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Map<String, String> _parseNetworkInfo(String rawInfo) {
    final lines = rawInfo.split('\n');
    final result = {'raw': rawInfo};

    for (var line in lines) {
      if (line.toLowerCase().contains('ssid')) {
        result['ssid'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('ip')) {
        result['ip'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('mac')) {
        result['mac'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('channel')) {
        result['channel'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('signal')) {
        result['signal'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('security')) {
        result['security'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('status')) {
        result['status'] = line.split(':').last.trim();
      }
    }

    return result;
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = Colors.deepOrange,
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
            color: iconColor ?? theme.colorScheme.primary,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
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