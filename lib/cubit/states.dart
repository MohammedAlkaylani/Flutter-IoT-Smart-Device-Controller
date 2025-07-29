abstract class AppStates {
  const AppStates();
}

class AppInitial extends AppStates {}

class DataGetting extends AppStates {}

class DataGot extends AppStates {}

class NavBarChanged extends AppStates {}

class JsonGet extends AppStates {}

class JsonGot extends AppStates {}

class JsonGetError extends AppStates {}

class PhotoTokenError extends AppStates {}

class TemperatureUpdated extends AppStates {}

class HumidityUpdated extends AppStates {}

class CookerModeChanged extends AppStates {}

class CookerNameChanged extends AppStates {}

class Cookersaved extends AppStates {}

class CookerStepChanged extends AppStates {}

class CookerCommandSending extends AppStates {}

class DeviceInfoError extends AppStates {}

class UserDataLoaded extends AppStates {}

class DeviceChangedState extends AppStates {}

class UserDataLoading extends AppStates {}

class UserDataRefreshed extends AppStates {}

class UserDataError extends AppStates {
  final String message;
  UserDataError(this.message);
}

class CookerCommandSuccess extends AppStates {}

class UpdateCompleted extends AppStates {}

class UserIDUpdated extends AppStates {}

class UserLoggedOut extends AppStates {}

class CookerCommandError extends AppStates {
  final String message;
  CookerCommandError(this.message);
}

class ProfilePictureUpdated extends AppStates {}

class DeviceRegistered extends AppStates {
  final String deviceID;
  DeviceRegistered(this.deviceID);
}

class DeviceRegistrationError extends AppStates {
  final String message;
  DeviceRegistrationError(this.message);
}

class NetworkInfoRequested extends AppStates {}

class NetworkInfoReceived extends AppStates {}

class UpdateCommandSent extends AppStates {
  final String message;
  final double progress; // Progress value between 0.0 and 1.0
  UpdateCommandSent({
    this.message = "Update command sent",
    this.progress = 0.0,
  });
  List<Object> get props => [message, progress];
}

class PauseStateChanged extends AppStates {}

class TimerUpdated extends AppStates {}

class DeviceInfoRequested extends AppStates {}

class DeviceInfoReceived extends AppStates {}

class StateUpdated extends AppStates {}

class ThemeChanged extends AppStates {}

class LocaleChanged extends AppStates {}

class PermissionRequestInProgress extends AppStates {}

class PermissionGranted extends AppStates {}

class PermissionDenied extends AppStates {}

class PermissionError extends AppStates {
  final String message;
  PermissionError(this.message);
}

class BluetoothConnecting extends AppStates {}

class BluetoothDisconnected extends AppStates {}

class BluetoothConnectionFailed extends AppStates {
  final String error;
  BluetoothConnectionFailed(this.error);
}

class BluetoothConnectionUpdated extends AppStates {}

class BluetoothConnectionError extends AppStates {
  final String message;
  BluetoothConnectionError(this.message);
}

class MqttConnecting extends AppStates {}

class MqttConnected extends AppStates {}

class MqttDisconnected extends AppStates {}

class MqttReconnecting extends AppStates {}

class MqttReconnected extends AppStates {}

class MqttReconnectFailed extends AppStates {}

class PauseButtonVisibilityChanged extends AppStates {}

class MqttConnectionFailed extends AppStates {
  final String message;
  MqttConnectionFailed(this.message);
}

class MqttConnectionError extends AppStates {
  final String message;
  MqttConnectionError(this.message);
}

class MqttSubscriptionError extends AppStates {
  final String message;
  MqttSubscriptionError(this.message);
}
