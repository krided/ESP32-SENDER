import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../model/engine_data.dart';

class BleManager extends ChangeNotifier {
  static const String deviceName = 'E46 Speeduino';
  static const Uuid serviceUuid = Uuid.parse('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
  static const Uuid charUuid = Uuid.parse('beb5483e-36e1-4688-b7f5-ea07361b26a8');

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  DiscoveredDevice? _device;

  bool _scanning = false;
  bool _connected = false;
  String _status = 'Idle';
  EngineData _data = EngineData.empty;

  bool get isScanning => _scanning;
  bool get isConnected => _connected;
  String get status => _status;
  EngineData get data => _data;

  BleManager() {
    _start();
  }

  void _setStatus(String s) {
    _status = s;
    notifyListeners();
  }

  Future<void> _start() async {
    _setStatus('Checking BLE state...');
    _ble.statusStream.listen((status) {
      if (status == BleStatus.ready) {
        _scan();
      } else {
        _setStatus('BLE not ready: $status');
      }
    });
    // Also try to scan immediately in case status is already ready
    if (await _ble.status == BleStatus.ready) {
      _scan();
    }
  }

  void _scan() {
    if (_scanning) return;
    _setStatus('Scanning...');
    _scanning = true;
    notifyListeners();

    _scanSub?.cancel();
    _scanSub = _ble
        .scanForDevices(withServices: [serviceUuid], scanMode: ScanMode.lowLatency)
        .listen((d) {
      if (d.name == deviceName || d.serviceUuids.contains(serviceUuid)) {
        _device = d;
        _scanSub?.cancel();
        _scanning = false;
        _connect(d.id);
      }
    }, onError: (e) {
      _scanning = false;
      _setStatus('Scan error: $e');
    });
  }

  void _connect(String id) {
    _setStatus('Connecting...');
    _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 10))
        .listen((update) {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          _connected = true;
          _setStatus('Connected');
          _subscribe();
          break;
        case DeviceConnectionState.disconnected:
          _connected = false;
          _setStatus('Disconnected, retrying...');
          _notifySub?.cancel();
          Future.delayed(const Duration(seconds: 2), () => _scan());
          break;
        default:
          break;
      }
    }, onError: (e) {
      _connected = false;
      _setStatus('Connect error: $e');
      Future.delayed(const Duration(seconds: 2), () => _scan());
    });
  }

  void _subscribe() {
    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charUuid,
      deviceId: _device!.id,
    );

    _notifySub?.cancel();
    _notifySub = _ble
        .subscribeToCharacteristic(characteristic)
        .listen((value) {
      try {
        final jsonStr = utf8.decode(value);
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        _data = EngineData.fromJson(map);
        notifyListeners();
      } catch (_) {
        // ignore malformed frames
      }
    }, onError: (e) {
      _setStatus('Notify error: $e');
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
