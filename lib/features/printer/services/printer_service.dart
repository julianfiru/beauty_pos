import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterDevice {
  final String name;
  final String mac;
  PrinterDevice({required this.name, required this.mac});
}

class PrinterService {
  Future<bool> checkIsBluetoothOn() async {
    if (kIsWeb) return true; // Simulator on Web
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      return false;
    }
  }

  Future<List<PrinterDevice>> getPairedDevices() async {
    if (kIsWeb) {
      // Mock devices for Web testing
      return [
        PrinterDevice(name: 'Simulated Printer 58mm', mac: '00:11:22:33:44:55'),
        PrinterDevice(name: 'Simulated Printer 80mm', mac: 'AA:BB:CC:DD:EE:FF'),
      ];
    }

    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices.map((d) => PrinterDevice(name: d.name, mac: d.macAdress)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      return true; // Always success in Web simulator
    }

    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    if (kIsWeb) return true;
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      return false;
    }
  }

  Future<bool> get connectionStatus async {
    if (kIsWeb) return false; // Handled by provider state instead
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printBytes(List<int> bytes) async {
    if (kIsWeb) {
      debugPrint('--- SIMULATED PRINT RECEIPT (Length: ${bytes.length} bytes) ---');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      return false;
    }
  }
}
