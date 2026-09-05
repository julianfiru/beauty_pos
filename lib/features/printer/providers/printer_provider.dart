import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/printer_service.dart';

final printerServiceProvider = Provider((ref) => PrinterService());

class PrinterState {
  final bool isBluetoothOn;
  final bool isConnected;
  final PrinterDevice? connectedDevice;
  final List<PrinterDevice> availableDevices;

  PrinterState({
    this.isBluetoothOn = false,
    this.isConnected = false,
    this.connectedDevice,
    this.availableDevices = const [],
  });

  PrinterState copyWith({
    bool? isBluetoothOn,
    bool? isConnected,
    PrinterDevice? connectedDevice,
    List<PrinterDevice>? availableDevices,
  }) {
    return PrinterState(
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isConnected: isConnected ?? this.isConnected,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      availableDevices: availableDevices ?? this.availableDevices,
    );
  }
}

class PrinterNotifier extends StateNotifier<AsyncValue<PrinterState>> {
  final PrinterService _service;

  PrinterNotifier(this._service) : super(const AsyncValue.loading()) {
    initPrinter();
  }

  Future<void> initPrinter() async {
    state = const AsyncValue.loading();
    try {
      final isOn = await _service.checkIsBluetoothOn();
      List<PrinterDevice> devices = [];
      if (isOn) {
        devices = await _service.getPairedDevices();
      }
      
      state = AsyncValue.data(PrinterState(
        isBluetoothOn: isOn,
        availableDevices: devices,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> scanDevices() async {
    if (state is AsyncData) {
      final currentState = state.value!;
      state = const AsyncValue.loading();
      try {
        final isOn = await _service.checkIsBluetoothOn();
        List<PrinterDevice> devices = [];
        if (isOn) {
          devices = await _service.getPairedDevices();
        }
        
        state = AsyncValue.data(currentState.copyWith(
          isBluetoothOn: isOn,
          availableDevices: devices,
        ));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<bool> connect(PrinterDevice device) async {
    try {
      final success = await _service.connect(device.mac);
      if (success && state is AsyncData) {
        state = AsyncValue.data(state.value!.copyWith(
          isConnected: true,
          connectedDevice: device,
        ));
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.copyWith(
          isConnected: false,
          connectedDevice: null,
        ));
      }
    } catch (e) {
      // Ignore
    }
  }
}

final printerProvider = StateNotifierProvider<PrinterNotifier, AsyncValue<PrinterState>>((ref) {
  final service = ref.watch(printerServiceProvider);
  return PrinterNotifier(service);
});
