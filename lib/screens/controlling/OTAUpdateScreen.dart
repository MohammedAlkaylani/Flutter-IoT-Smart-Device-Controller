import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class FirmwareUpdateScreen extends StatefulWidget {
  const FirmwareUpdateScreen({Key? key}) : super(key: key);

  @override
  State<FirmwareUpdateScreen> createState() => _FirmwareUpdateScreenState();
}

class _FirmwareUpdateScreenState extends State<FirmwareUpdateScreen> {
  bool _isChecking = false;
  bool _updateAvailable = false;
  String _updateFile = '';
  String _serverIP = '192.168.1.1'; // Generic default IP
  double _progress = 0.0;
  bool _updateCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  void dispose() {
    final cubit = BlocProvider.of<AppCubit>(context);
    cubit.doneUpdate = false;
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isChecking = true);
    try {
      final response = await http.head(Uri.parse('http://$_serverIP/firmware.bin'));
      setState(() {
        _updateAvailable = response.statusCode == 200;
        _updateFile = 'firmware.bin';
      });
      if (_updateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New firmware update available!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking for update: ${e.toString()}')),
      );
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _startUpdate() {
    setState(() {
      _progress = 0.0;
      _updateCompleted = false;
    });
    
    final cubit = BlocProvider.of<AppCubit>(context);
    cubit.sendUpdateCommand('http://$_serverIP/$_updateFile');
    
    cubit.stream.listen((state) {
      if (state is UpdateCommandSent) {
        setState(() => _progress = state.progress);
      }
      if (cubit.doneUpdate && !_updateCompleted) {
        _updateCompleted = true;
        _showUpdateCompleteDialog();
      }
    });
  }

  void _showUpdateCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Complete"),
          content: const Text(
              "The firmware update has been successfully completed. The device will restart automatically."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                final cubit = BlocProvider.of<AppCubit>(context);
                cubit.doneUpdate = false;
                setState(() {
                  _updateCompleted = false;
                  _updateAvailable = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return BlocListener<AppCubit, AppStates>(
      listener: (context, state) {
        final cubit = BlocProvider.of<AppCubit>(context);
        if (cubit.doneUpdate && !_updateCompleted) {
          _updateCompleted = true;
          _showUpdateCompleteDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Firmware Update"),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenSize.height * 0.02),
              _buildUpdateStatusSection(screenSize),
              SizedBox(height: screenSize.height * 0.04),
              if (_updateAvailable) ...[
                SizedBox(height: screenSize.height * 0.04),
                _buildUpdateButton(screenSize),
              ],
              SizedBox(height: screenSize.height * 0.02),
              _buildServerSettingsSection(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateStatusSection(Size screenSize) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          children: [
            if (_isChecking) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                "Checking for updates...",
                style: TextStyle(fontSize: screenSize.width * 0.04),
              ),
            ] else if (_updateAvailable) ...[
              Icon(
                Icons.system_update,
                size: screenSize.width * 0.15,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 8),
              Text(
                "Update Available",
                style: TextStyle(
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _updateFile,
                style: TextStyle(
                  fontSize: screenSize.width * 0.035,
                  color: Colors.grey,
                ),
              ),
            ] else ...[
              Icon(
                Icons.check_circle,
                size: screenSize.width * 0.15,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              Text(
                "No updates available",
                style: TextStyle(
                  fontSize: screenSize.width * 0.045,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(Size screenSize) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startUpdate,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: screenSize.width * 0.04),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        child: Text(
          "Start Update",
          style: TextStyle(fontSize: screenSize.width * 0.045),
        ),
      ),
    );
  }

  Widget _buildServerSettingsSection(Size screenSize) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Server Settings",
              style: TextStyle(
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: "Server IP",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _serverIP = value),
              controller: TextEditingController(text: _serverIP),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _checkForUpdate,
                child: Text(
                  "Check Again",
                  style: TextStyle(fontSize: screenSize.width * 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}