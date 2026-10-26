/// App-wide constants that are not a design token.
class AppConfig {
  AppConfig._();

  static const String appTitle = 'MSP430 Lab';

  /// Names the pipe a second launch on Windows uses to reach the running
  /// window (windows_single_instance).
  static const String singleInstanceId = 'msp430_lab_single_instance';

  /// Windows' App User Model ID: `Company.App`.
  static const String windowsAppUserModelId = 'com.example.msp430lab';
}
