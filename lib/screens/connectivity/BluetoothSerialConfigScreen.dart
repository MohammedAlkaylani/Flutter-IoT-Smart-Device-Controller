import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_bloc/flutter_bloc.dart';

class BluetoothConfigScreen extends StatefulWidget {
  const BluetoothConfigScreen({super.key});

  @override
  State<BluetoothConfigScreen> createState() => _BluetoothConfigScreenState();
}

class _BluetoothConfigScreenState extends State<BluetoothConfigScreen> {
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _statusSubscription;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSendingCredentials = false;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String _statusMessage = "Ready to scan for devices";
  String? deviceName;

  // Encryption constants
  static const String _encryptionKey = "32characterslongsecretkeymustbe1";
  static const String _encryptionIV = "16charIV12345678";
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 15);
  
  // BLE Service UUIDs
  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String _writeCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String _statusCharUuid = "aeb5483e-36e1-4688-b7f5-ea07361b26a9";

  @override
  void initState() {
    super.initState();
    _setupBluetoothListener();
  }

  void _setupBluetoothListener() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _updateStatus("Bluetooth ready");
      } else {
        _updateStatus("Bluetooth is off");
        _resetConnectionState();
      }
    });
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  void _resetConnectionState() {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _connectedDevice = null;
      });
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;
    final permissions = await Future.wait([
      Permission.bluetoothScan.request(),
      Permission.bluetoothConnect.request(),
      Permission.locationWhenInUse.request(),
    ]);
    return permissions.every((status) => status.isGranted);
  }

  Future<void> _startDeviceDiscovery() async {
    if (!await _checkAndRequestPermissions()) {
      _showPermissionError();
      return;
    }
    _prepareForScanning();
    try {
      await FlutterBluePlus.startScan(timeout: _scanTimeout);
      _listenForScanResults();
      _setScanTimeout();
    } catch (e) {
      _handleScanError(e);
    }
  }

  void _prepareForScanning() {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _statusMessage = "Discovering devices...";
    });
  }

  void _listenForScanResults() {
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final compatibleDevices = results
          .where((result) => result.device.localName != null)
          .where((result) => result.device.localName!.contains('SmartDevice') ||
              result.device.localName!.contains('Controller'))
          .map((result) => result.device)
          .toList();
      if (compatibleDevices.isNotEmpty && mounted) {
        setState(() => _discoveredDevices = compatibleDevices);
      }
    });
  }

  void _setScanTimeout() {
    Future.delayed(_scanTimeout, () {
      FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = _discoveredDevices.isEmpty
              ? 'No compatible devices found'
              : 'Found ${_discoveredDevices.length} device(s)';
        });
      }
    });
  }

  void _showPermissionError() {
    _updateStatus('Permissions required');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bluetooth and location permissions are required'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'SETTINGS',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  void _handleScanError(dynamic error) {
    _updateStatus('Scan error: ${error.toString()}');
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    debugPrint('Starting connection to ${device.localName}');
    _updateConnectionState(ConnectionState.connecting, device);
    try {
      debugPrint('Attempting to connect...');
      await device.connect(
        autoConnect: false,
        timeout: _connectionTimeout,
      );
      debugPrint('Connection established, discovering services...');
      await establishConnection(device);
    } on TimeoutException {
      debugPrint('Connection timed out');
      _handleConnectionTimeout();
    } catch (e) {
      debugPrint('Connection error: $e');
      _handleConnectionError(e);
    }
  }

  void _updateConnectionState(ConnectionState state, [BluetoothDevice? device]) {
    if (!mounted) return;
    setState(() {
      _connectionState = state;
      _isConnecting = state == ConnectionState.connecting;
      _isConnected = state == ConnectionState.connected;
      _connectedDevice = device;
      switch (state) {
        case ConnectionState.connecting:
          _statusMessage = "Connecting to ${device?.localName}...";
          break;
        case ConnectionState.connected:
          deviceName = device?.localName;
          _statusMessage = "Connected to $deviceName";
          break;
        case ConnectionState.disconnected:
          _statusMessage = "Ready to scan";
          break;
      }
    });
  }

  Future<void> establishConnection(BluetoothDevice device) async {
    final services = await device.discoverServices();
    final targetService = services.firstWhere(
          (s) => s.uuid.toString() == _serviceUuid,
      orElse: () => throw Exception("BLE service not found"),
    );

    // Set up status notifications
    final statusChar = targetService.characteristics.firstWhere(
          (c) => c.uuid.toString() == _statusCharUuid,
      orElse: () => throw Exception("Status characteristic not found"),
    );

    await statusChar.setNotifyValue(true);
    _statusSubscription = statusChar.onValueReceived.listen((value) {
      final statusMessage = String.fromCharCodes(value);
      _showStatusDialog("The device is connected successfully");
    });

    _updateConnectionState(ConnectionState.connected, device);
    _showNetworkCredentialsDialog();
  }

  void _showStatusDialog(String message) {
    if (!mounted || _connectionState != ConnectionState.connected) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Connection Status"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnect();
              Navigator.pop(context, true);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleConnectionTimeout() {
    _updateStatus("Connection timeout");
    _updateConnectionState(ConnectionState.disconnected);
  }

  void _handleConnectionError(dynamic error) {
    _updateStatus("Connection failed: ${error.toString()}");
    _updateConnectionState(ConnectionState.disconnected);
  }

  void _showNetworkCredentialsDialog() {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CredentialsDialog(
        ssidController: ssidController,
        passwordController: passwordController,
        onCancel: () {
          Navigator.pop(context);
          _disconnect();
        },
        onSend: () => _sendNetworkCredentials(
          ssidController.text,
          passwordController.text,
        ),
        isSending: _isSendingCredentials,
      ),
    );
  }

  Future<void> _sendNetworkCredentials(String ssid, String password) async {
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WiFi SSID is required')),
      );
      return;
    }
    setState(() => _isSendingCredentials = true);
    try {
      final payload = {
        'ssid': ssid,
        'password': password,
        'deviceID': "Device123", // Generic device ID
        'userID': "User123", // Generic user ID
      };
      final encryptedMessage = _encryptData(jsonEncode(payload));
      await _writeToCharacteristic(encryptedMessage);
      _handleSendSuccess();
    } catch (e) {
      _handleSendError(e);
    } finally {
      if (mounted) {
        setState(() => _isSendingCredentials = false);
      }
    }
  }

  String _encryptData(String plainText) {
    try {
      final key = encrypt.Key.fromUtf8(_encryptionKey);
      final iv = encrypt.IV.fromUtf8(_encryptionIV);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.encrypt(plainText, iv: iv).base64;
    } catch (e) {
      throw Exception('Data encryption failed: $e');
    }
  }

  Future<void> _writeToCharacteristic(String message) async {
    final services = await _connectedDevice!.discoverServices();
    final targetService = services.firstWhere(
          (s) => s.uuid.toString() == _serviceUuid,
      orElse: () => throw Exception("Service not found"),
    );
    final writeChar = targetService.characteristics.firstWhere(
          (c) => c.uuid.toString() == _writeCharUuid,
      orElse: () => throw Exception("Write characteristic not found"),
    );
    await writeChar.write(message.codeUnits);
  }

  void _handleSendSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WiFi credentials sent successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _handleSendError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.toString()}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _statusSubscription?.cancel();
        _statusSubscription = null;
        try {
          final services = await _connectedDevice!.discoverServices();
          final targetService = services.firstWhere(
                (s) => s.uuid.toString() == _serviceUuid,
          );
          final statusChar = targetService.characteristics.firstWhere(
                (c) => c.uuid.toString() == _statusCharUuid,
          );
          await statusChar.setNotifyValue(false);
        } catch (e) {
          debugPrint('Error cleaning up notifications: $e');
        }
        await _connectedDevice!.disconnect();
      } finally {
        _updateConnectionState(ConnectionState.disconnected);
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _disconnect();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Configuration"),
        centerTitle: true,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: _disconnect,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusIndicator(),
            const SizedBox(height: 24),
            _buildActionButton(),
            const SizedBox(height: 24),
            _buildDeviceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getConnectionStateIcon(),
            color: _getConnectionStateColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConnectionStateIcon() {
    switch (_connectionState) {
      case ConnectionState.connected:
        return Icons.bluetooth_connected;
      case ConnectionState.connecting:
        return Icons.bluetooth_searching;
      case ConnectionState.disconnected:
        return Icons.bluetooth_disabled;
    }
  }

  Color _getConnectionStateColor() {
    switch (_connectionState) {
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.connecting:
        return Colors.orange;
      case ConnectionState.disconnected:
        return Colors.grey;
    }
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.search),
      label: Text(_isScanning ? "Scanning..." : "Scan for Devices"),
      onPressed: _isScanning || _isConnecting ? null : _startDeviceDiscovery,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_discoveredDevices.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "No devices found",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.separated(
        itemCount: _discoveredDevices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _discoveredDevices[index];
          return _buildDeviceListItem(device);
        },
      ),
    );
  }

  Widget _buildDeviceListItem(BluetoothDevice device) {
    final isCurrentDevice = _connectedDevice?.remoteId == device.remoteId;
    return ListTile(
      leading: Icon(
        Icons.devices,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        device.localName ?? 'Unknown Device',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        device.remoteId.toString(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: isCurrentDevice && _isConnecting
          ? const CircularProgressIndicator()
          : null,
      onTap: () => _connectToDevice(device),
    );
  }
}

class CredentialsDialog extends StatelessWidget {
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final bool isSending;

  const CredentialsDialog({
    super.key,
    required this.ssidController,
    required this.passwordController,
    required this.onCancel,
    required this.onSend,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Network Configuration"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: "WiFi SSID",
                hintText: "Enter your network name",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "WiFi Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: isSending ? null : onSend,
          child: isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("SEND CREDENTIALS"),
        ),
      ],
    );
  }
}

enum ConnectionState {
  connected,
  connecting,
  disconnected,
}