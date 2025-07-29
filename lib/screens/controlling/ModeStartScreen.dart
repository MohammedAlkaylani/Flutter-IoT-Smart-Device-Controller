import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<AppCubit>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Information'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context,
              title: 'Device Status',
              items: [
                _InfoItem(label: 'Connection Status', value: 'Connected'),
                _InfoItem(label: 'Device ID', value: cubit.deviceID ?? 'N/A'),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            _buildInfoCard(
              context,
              title: 'Usage Statistics',
              items: [
                _InfoItem(label: 'Power Cycles', value: '125'),
                _InfoItem(label: 'Total Usage Hours', value: '87.5'),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            _buildInfoCard(
              context,
              title: 'Performance Metrics',
              items: [
                _InfoItem(label: 'Current Temperature', value: '65°C'),
                _InfoItem(label: 'Max Temperature', value: '120°C'),
                _InfoItem(label: 'Power Consumption', value: '750W'),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            _buildInfoCard(
              context,
              title: 'Network Information',
              items: [
                _InfoItem(label: 'WiFi SSID', value: 'HomeNetwork'),
                _InfoItem(label: 'Signal Strength', value: 'Excellent'),
                _InfoItem(label: 'IP Address', value: '192.168.1.100'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}