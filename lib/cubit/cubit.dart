import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;

/// Main Cubit class for managing application state and MQTT communication
class AppCubit extends Cubit<AppStates> {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    emit(LocaleChanged());
  }

  AppCubit() : super(AppInitial()) {
    initMqtt();
    step1ValueController = TextEditingController();
    step1TimeController = TextEditingController();
    step2ValueController = TextEditingController();
    step2TimeController = TextEditingController();
    step3ValueController = TextEditingController();
    step3TimeController = TextEditingController();
  }

  Future<void> registerDeviceWithServer() async {
    if (userID == null) {
      emit(DeviceRegistrationError('User not authenticated'));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://example.com/api/register_device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceID,
          'user_id': userID,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (deviceID != null) {
          emit(DeviceRegistered(deviceID!));
        } else {
          emit(DeviceRegistrationError('Device ID is null'));
        }
      } else {
        emit(DeviceRegistrationError(data['error'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(DeviceRegistrationError(e.toString()));
    }
  }

  Future<void> refreshUserData() async {
    emit(UserDataLoading());

    try {
      final userData = await AppServices.getUserData();
      if (userData != null) {
        final response = await AppServices.fetchCurrentUserData(userData['UserID']);

        if (response['success'] == true) {
          final freshData = response['user'];
          await AppServices.saveUserData(freshData);

          userID = freshData['UserID'] ?? 0;
          username = freshData['Username'] ?? '';

          if (freshData['ProfilePicturePath'] != null) {
            userProfilePicture = freshData['ProfilePicturePath'];
          } else {
            final picturePath = await AppServices.getProfilePicture(userID);
            if (picturePath != null) {
              userProfilePicture = picturePath;
            }
          }

          emit(UserDataRefreshed());
        } else {
          emit(UserDataError('Failed to fetch user data'));
        }
      }
    } catch (e) {
      emit(UserDataError(e.toString()));
    }
  }

  Future<void> initializeUserData() async {
    final isLoggedIn = await AppServices.isLoggedIn();
    if (isLoggedIn) {
      await refreshUserData();
    }
  }

  Future<void> logout() async {
    await AppServices.clearUserData();
    userID = 0;
    userProfilePicture = null;
    emit(UserLoggedOut());
  }

  Future<void> updateUserID(int newUserID) async {
    userID = newUserID;
    emit(UserIDUpdated());
    _resubscribeTopics();
    await registerDeviceWithServer();
  }

  Future<void> updateProfilePicture(String imagePath) async {
    userProfilePicture = imagePath;
    emit(ProfilePictureUpdated());
  }

  File? _profilePicture;
  File? get profilePicture => _profilePicture;
  set profilePicture(File? image) {
    _profilePicture = image;
    emit(ProfilePictureUpdated());
  }

  static AppCubit get(context) => BlocProvider.of(context);

  // MQTT Client
  late MqttServerClient _client;

  // Device control variables
  String deviceMode = 'power';
  late String deviceName = '';
  bool hasSecondStep = false;
  bool hasThirdStep = false;
  bool save = false;
  late TextEditingController step1ValueController;
  late TextEditingController step1TimeController;
  late TextEditingController step2ValueController;
  late TextEditingController step2TimeController;
  late TextEditingController step3ValueController;
  late TextEditingController step3TimeController;
  String networkInfo = 'No network data';
  double currentRssi = 0.0;
  Timer? _rssiTimer;
  bool isPaused = false;
  int timerValue = 0;
  String deviceInfo = 'No device data';
  bool showPauseButton = false;
  bool get shouldShowTimer => showPauseButton;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool doneUpdate = false;
  final Duration _reconnectDelay = Duration(seconds: 5);
  final int _maxReconnectAttempts = 5;

  String? userProfilePicture;
  int userID = 0;
  String deviceID = "Device123";
  String? deviceAddress;
  String username = '';
  File? _profilePictureFile;
  String? connectedDeviceName;
  bool get isDeviceConnected => connectedDeviceName != null;

  void setActiveDevice(String deviceId, String deviceAddress) {
    deviceID = deviceId;
    this.deviceAddress = deviceAddress;
    emit(DeviceChangedState());
  }

  String stringToHex(String input) {
    List<int> bytes = utf8.encode(input);
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }

  void initMqtt() async {
    _client = MqttServerClient('mqtt.example.com', '');
    _client.port = 1883;
    _client.keepAlivePeriod = 10;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();

    _client.connectionMessage = connMess;
    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT connected');
      _client.subscribe('device/status', MqttQos.atLeastOnce);
    } else {
      print('ERROR: MQTT connection failed');
    }

    _client.subscribe('DEVICE/$userID/$deviceID/timer', MqttQos.atLeastOnce);
    _client.subscribe('DEVICE/$userID/$deviceID/deviceinfo/', MqttQos.atLeastOnce);
    _client.subscribe('DEVICE/$userID/$deviceID/pause', MqttQos.atLeastOnce);
    _client.subscribe('DEVICE/$userID/$deviceID/networkinformation/response', MqttQos.atLeastOnce);
    _client.subscribe('/update/$userID/$deviceID/url/', MqttQos.atLeastOnce);

    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final topic = c[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(topic);

      if (topic == 'DEVICE/$userID/$deviceID/networkinformation/response') {
        print('Received network info: $payload');
        try {
          final data = jsonDecode(payload);
          networkInfo = '''
                    SSID: ${data['ssid']}
                    IP: ${data['ip']}
                    RSSI: ${data['rssi']} dBm
                    MAC: ${data['mac']}
                    Channel: ${data['channel']}''';

          currentRssi = data['rssi']?.toDouble() ?? 0.0;
          emit(NetworkInfoReceived());
        } catch (e) {
          print('Error parsing network info: $e');
          networkInfo = 'Error parsing network data';
        }
      } else if (topic == 'DEVICE/$userID/$deviceID/deviceinfo/') {
        print('Raw device info received: $payload');
        try {
          deviceInfo = parseDeviceInfo(payload);
          emit(DeviceInfoReceived());
        } catch (e) {
          print('Error parsing device info: $e');
          deviceInfo = 'Error: ${e.toString()}';
          emit(DeviceInfoError());
        }
      } else if (topic == 'DEVICE/$userID/$deviceID/pause') {
        if (payload == 'start') {
          showPauseButton = true;
          isPaused = false;
          emit(PauseButtonVisibilityChanged());
        } else if (payload == 'end') {
          showPauseButton = false;
          isPaused = true;
          emit(PauseButtonVisibilityChanged());
        } else if (payload == 'suspend') {
          isPaused = true;
          emit(PauseStateChanged());
        } else if (payload == 'continue') {
          isPaused = false;
          emit(PauseStateChanged());
        }
      } else if (topic == 'DEVICE/$userID/$deviceID/timer') {
        updateTimer(int.tryParse(payload) ?? 0);
      } else if (topic == '/update/$userID/$deviceID/url/') {
        if(payload == 'done'){
          print("The update done");
          doneUpdate = true;
          emit(UpdateCompleted());
        }
        updateTimer(int.tryParse(payload) ?? 0);
      }
    });
  }

  void sendModeCommand({
    required String mode,
    required String name,
    required int power,
    required int time,
  }) {
    emit(DeviceCommandSending());

    try {
      final message = {
        'mode': mode,
        'name': name,
        'steps': [
          {
            'value': power,
            'time': time,
          }
        ]
      };

      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(message));
      _client.publishMessage('DEVICE/$userID/$deviceID/newmode',
          MqttQos.atLeastOnce, builder.payload!);
      emit(DeviceCommandSuccess());
    } catch (e) {
      emit(DeviceCommandError('Failed to send mode command: $e'));
    }
  }

  final Map<String, Map<String, int>> modeSettings = {
    'mode1': {'power': 99, 'time': 3},
    'mode2': {'power': 75, 'time': 2},
    'mode3': {'power': 70, 'time': 1},
    'mode4': {'power': 85, 'time': 2},
    'mode5': {'power': 65, 'time': 1},
  };

  Future<bool> requestBluetoothPermissions() async {
    emit(PermissionRequestInProgress());
    bool hasPermissions = false;
    try {
      if (Platform.isAndroid) {
        if (await Permission.bluetoothConnect.request().isGranted &&
            await Permission.bluetoothScan.request().isGranted) {
          hasPermissions = true;
        }
        else if (await Permission.bluetooth.request().isGranted) {
          hasPermissions = true;
        }
      } else {
        hasPermissions = true;
      }

      if (hasPermissions) {
        emit(PermissionGranted());
      } else {
        emit(PermissionDenied());
      }
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
    return hasPermissions;
  }

  String getValueFromDeviceInfo(String deviceInfo, String key, String fallback) {
    if (deviceInfo.isEmpty || !deviceInfo.contains('$key:')) return fallback;

    try {
      final lines = deviceInfo.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.startsWith('$key:')) {
          return line.substring(line.indexOf(':') + 1).trim();
        }
      }
      return fallback;
    } catch (e) {
      print('Error parsing $key: $e');
      return fallback;
    }
  }

  String parseDeviceInfo(String payload) {
    try {
      final data = jsonDecode(payload);

      if (data is Map) {
        return '''
      pluggedIn: ${data['pluggedIn'] ?? 'N/A'}
      turnedOn: ${data['turnedOn'] ?? 'N/A'}
      secondsOnCN: ${data['secondsOnCN'] ?? data['secondsOn'] ?? 'N/A'}
      error: ${data['error'] ?? 'N/A'}
      lastError: ${data['lastError'] ?? 'N/A'}
      allTimeWS: ${data['allTimeWS'] ?? 'N/A'}
      sessionWS: ${data['sessionWS'] ?? 'N/A'}
      temp1Max: ${data['temp1Max'] ?? 'N/A'}
      temp2Max: ${data['temp2Max'] ?? 'N/A'}
      volt: ${data['volt'] ?? 'N/A'}
      power_: ${data['power_'] ?? 'N/A'}
      temp1: ${data['temp1'] ?? 'N/A'}
      temp2: ${data['temp2'] ?? 'N/A'}''';
      } else {
        return payload;
      }
    } catch (e) {
      return payload;
    }
  }

  void requestDeviceInfo() {
    print('Requesting device info...');
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('get_device_info');
      _client.publishMessage(
        'DEVICE/$userID/$deviceID/deviceinfo/request',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      print('Device info request sent');
      emit(DeviceInfoRequested());
    } else {
      print('MQTT not connected, cannot send request');
    }
  }

  void togglePause() {
    isPaused = !isPaused;

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(isPaused ? 'pause' : 'resume');
      _client.publishMessage(
        'DEVICE/$userID/$deviceID/pause',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      emit(PauseStateChanged());
    } catch (e) {
      isPaused = !isPaused;
      emit(DeviceCommandError('Failed to send pause command: $e'));
    }
  }

  void updateTimer(int value) {
    timerValue = value;
    emit(TimerUpdated());
  }

  void setDeviceMode(String mode) {
    deviceMode = mode;
    emit(DeviceModeChanged());
  }

  void setDeviceName(String name) {
    deviceName = name;
    emit(DeviceNameChanged());
  }

  void toggleSecondStep(bool value) {
    hasSecondStep = value;
    emit(DeviceStepChanged());
  }

  void toggleThirdStep(bool value) {
    hasThirdStep = value;
    emit(DeviceStepChanged());
  }

  void toggleSave(bool value) {
    save = value;
    emit(Devicesaved());
  }

  void sendDeviceCommand() {
    emit(DeviceCommandSending());

    if (step1ValueController.text.isEmpty || step1TimeController.text.isEmpty) {
      emit(DeviceCommandError('Please fill all required fields'));
      return;
    }

    if (hasSecondStep &&
        (step2ValueController.text.isEmpty ||
            step2TimeController.text.isEmpty)) {
      emit(DeviceCommandError('Please fill all step 2 fields or disable it'));
      return;
    }
    if (hasThirdStep &&
        (step3ValueController.text.isEmpty ||
            step3TimeController.text.isEmpty)) {
      emit(DeviceCommandError('Please fill all step 3 fields or disable it'));
      return;
    }
    final builder = MqttClientPayloadBuilder();
    final hexName = stringToHex(deviceName);
    try {
      final message = {
        'mode': deviceMode,
        'name': hexName,
        'steps': [
          {
            'value': int.parse(step1ValueController.text),
            'time': int.parse(step1TimeController.text),
          },
          if (hasSecondStep)
            {
              'value': int.parse(step2ValueController.text),
              'time': int.parse(step2TimeController.text),
            },
          if (hasThirdStep)
            {
              'value': int.parse(step3ValueController.text),
              'time': int.parse(step3TimeController.text),
            },
        ]
      };

      builder.addString(jsonEncode(message));
      if (save) {
        _client.publishMessage(
          'DEVICE/$userID/$deviceID/savemode',
          MqttQos.atLeastOnce,
          builder.payload!,
        );
        emit(DeviceCommandSuccess());
      } else {
        _client.publishMessage(
          'DEVICE/$userID/$deviceID/newmode',
          MqttQos.atLeastOnce,
          builder.payload!,
        );
        emit(DeviceCommandSuccess());
      }
    } catch (e) {
      emit(DeviceCommandError('Failed to send command: $e'));
    }
  }

  bool showManualControl = false;

  void toggleManualControl(bool value) {
    showManualControl = value;
    emit(StateUpdated());
  }

  void _onConnected() {
    print('MQTT connected');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _onDisconnected() {
    print('MQTT disconnected');
    emit(MqttDisconnected());

    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectAttempts = 0;
      _startReconnectLoop();
    }
  }

  void _startReconnectLoop() {
    _reconnectTimer = Timer.periodic(_reconnectDelay, (timer) async {
      _reconnectAttempts++;

      print('Attempting MQTT reconnect #$_reconnectAttempts');
      try {
        await _client.connect();
      } catch (e) {
        print('Reconnect attempt failed: $e');
        _client.disconnect();
      }

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        print('Reconnected to MQTT');
        timer.cancel();
        _reconnectAttempts = 0;
        emit(MqttReconnected());
        _resubscribeTopics();
      } else if (_reconnectAttempts >= _maxReconnectAttempts) {
        print('Max reconnect attempts reached.');
        timer.cancel();
        emit(MqttReconnectFailed());
      }
    });
  }

  void _resubscribeTopics() {
    _client.subscribe('device/status', MqttQos.atLeastOnce);
    _client.subscribe('DEVICE/$userID/$deviceID/timer', MqttQos.atLeastOnce);
    _client.subscribe(
        'DEVICE/$userID/$deviceID/deviceinfo/', MqttQos.atLeastOnce);
  }

  String formatDuration(int totalSeconds) {
    final minutes = (totalSeconds + 59) / 60;
    final hours = minutes / 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String formatDigitalTime(int totalSeconds) {
    final minutes = (totalSeconds + 59) ~/ 60 - 60;
    final hours = totalSeconds ~/ 3600;

    return [
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
    ].join(':');
  }

  int _durationToMinutes(String duration) {
    try {
      if (duration.contains('h') && duration.contains('min')) {
        final parts = duration.split(' ');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[2]);
        return hours * 60 + minutes;
      } else if (duration.contains('h')) {
        return int.parse(duration.split(' ')[0]) * 60;
      } else if (duration.contains('min')) {
        return int.parse(duration.split(' ')[0]);
      }
      return 0;
    } catch (e) {
      print('Error parsing duration: $e');
      return 0;
    }
  }

  void sendMultiStepCommand({
    required String modeName,
    required String modeType,
    required List<Map<String, String>> steps,
    required bool saveMode,
  }) {
    emit(DeviceCommandSending());

    try {
      if (modeName.isEmpty) {
        emit(DeviceCommandError('Please enter a mode name'));
        return;
      }

      for (final step in steps) {
        if (step['power'] == null || step['duration'] == null) {
          emit(DeviceCommandError('Please complete all steps'));
          return;
        }
      }

      final formattedSteps = steps.map((step) {
        return {
          'value': int.parse(step['power']!),
          'time': _durationToMinutes(step['duration']!),
        };
      }).toList();

      final message = {
        'mode': modeType.toLowerCase(),
        'name': stringToHex(modeName),
        'steps': formattedSteps,
      };

      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(message));

      final topic = saveMode
          ? 'DEVICE/$userID/$deviceID/savemode'
          : 'DEVICE/$userID/$deviceID/newmode';

      _client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      emit(DeviceCommandSuccess());
    } catch (e) {
      emit(DeviceCommandError('Failed to send command: $e'));
    }
  }

  void initNetworkMonitoring() {
    _rssiTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _requestRssiUpdate();
    });
  }

  void _requestRssiUpdate() {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('get_rssi');
      _client.publishMessage(
        'DEVICE/$userID/$deviceID/networkinformation/request',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }
  }

  void requestNetworkInfo() {
    print('Requesting network info...');
    print('Connection state: ${_client.connectionStatus?.state}');
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('get_network_info');
      _client.publishMessage(
        'DEVICE/$userID/$deviceID/networkinformation/request',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      print('Network info request sent');
      emit(NetworkInfoRequested());
    } else {
      print('MQTT not connected, cannot send request');
    }
  }

  void sendUpdateCommand(String fileUrl) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        emit(UpdateCommandSent(progress: 0.1));

        final builder = MqttClientPayloadBuilder();
        builder.addString(fileUrl);
        _client.publishMessage(
          '/update/$userID/$deviceID/url/',
          MqttQos.atLeastOnce,
          builder.payload!,
        );

        emit(UpdateCommandSent(progress: 0.5));

        emit(UpdateCommandSent(
          message: "Update command sent successfully",
          progress: 1.0,
        ));
      } catch (e) {
        emit(UpdateCommandSent(
          message: 'Failed to send update command: $e',
          progress: 0.0,
        ));
      }
    } else {
      emit(UpdateCommandSent(
        message: 'MQTT not connected',
        progress: 0.0,
      ));
    }
  }

  @override
  Future<void> close() {
    step1ValueController.dispose();
    step1TimeController.dispose();
    step2ValueController.dispose();
    step2TimeController.dispose();
    step3ValueController.dispose();
    step3TimeController.dispose();

    _rssiTimer?.cancel();

    return super.close();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}