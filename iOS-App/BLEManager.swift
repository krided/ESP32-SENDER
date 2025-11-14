import Foundation
import CoreBluetooth

struct EngineData: Codable {
    var rpm: Int = 0
    var clt: Int = 0
    var iat: Int = 0
    var tps: Int = 0
    var map: Int = 0
    var battery: String = "0"
    var advance: Int = 0
    var pulsewidth: String = "0"
    var o2: Int = 0
    var boostDuty: Int = 0
    var boostTarget: Int = 0
    var wrpm: Int = 6800
    var wclt: Int = 95
    var wtps: Int = 95
    var wmap: Int = 250
    var wbattery: Int = 15
    var wadvance: Int = 35
}

class BLEManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var engineData = EngineData()
    @Published var connectionStatus = "Disconnected"
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            connectionStatus = "Scanning..."
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            connectionStatus = "Bluetooth Off"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        connectionStatus = "Connecting..."
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected"
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Disconnected"
        isConnected = false
        startScanning()
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if let json = try? JSONDecoder().decode(EngineData.self, from: data) {
            DispatchQueue.main.async {
                self.engineData = json
            }
        }
    }
}
