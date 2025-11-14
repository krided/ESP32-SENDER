// ESP32-SENDER - Receives engine data via ESP-NOW and sends ESPin data back
// This code communicates with Serial3toBMWcan_ESP32_BASIC via ESP-NOW protocol
// Hardware: ESP32 WROOM

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

#include <esp_now.h>
#include <WiFi.h>
#include <Ticker.h>
#include "Config.h"
//#include <SPI.h>      // Uncomment if using SPI devices
//#include <Wire.h>     // Uncomment if using I2C devices
#if SCREEN
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#endif
#include <BLEDevice.h>
#include <BLEServer.h>
//#include <BLEUtils.h> // Uncomment if needed
#include <BLE2902.h>
#include <ArduinoJson.h>

// ================= ESP-NOW DATA STRUCTURES =================
// Structure for ESP-NOW data RECEIVING (all engine data from main ESP32)
typedef struct {
  uint32_t timestamp;           // Timestamp of data
  uint16_t rpm;                 // Engine RPM
  uint16_t pulsewidth;          // Fuel injection pulse width
  uint8_t clt;                  // Coolant temperature
  uint8_t iat;                  // Intake air temperature
  uint8_t tps;                  // Throttle position sensor
  uint8_t map;                  // Manifold absolute pressure (stored as signed in uint8)
  uint8_t battery;              // Battery voltage
  uint8_t o2;                   // Oxygen sensor
  uint8_t advance;              // Ignition advance
  uint8_t boostDuty;            // Boost duty (stored as signed in uint8)
  uint8_t boostTarget;          // Boost target (stored as signed in uint8)
  uint16_t canin_1;             // CAN input channel 1
  uint16_t canin_2;             // CAN input channel 2
  uint16_t canin_3;             // CAN input channel 3
  uint16_t canin_4;             // CAN input channel 4
  uint16_t canin_5;             // CAN input channel 5
  uint16_t canin_6;             // CAN input channel 6
  uint16_t canin_7;             // CAN input channel 7
  uint16_t canin_8;             // CAN input channel 8
  uint16_t canin_9;             // CAN input channel 9
  uint16_t canin_10;            // CAN input channel 10
  uint16_t canin_11;            // CAN input channel 11
  uint16_t canin_12;            // CAN input channel 12
  uint16_t canin_13;            // CAN input channel 13
  uint16_t canin_14;            // CAN input channel 14
  uint16_t canin_15;            // CAN input channel 15
  uint16_t canin_16;            // CAN input channel 16 (fuel pump or other)
  uint8_t statusFlags;          // Status bitfield
  uint8_t errorFlags;           // Error bitfield
} espnow_data_recv_t;

// Structure for ESP-NOW data SENDING (ESPin 1-10 will be mapped to CANin 7-16 by receiver)
typedef struct {
  uint16_t espin_1;             // ESP input channel 1
  uint16_t espin_2;             // ESP input channel 2
  uint16_t espin_3;             // ESP input channel 3
  uint16_t espin_4;             // ESP input channel 4
  uint16_t espin_5;             // ESP input channel 5
  uint16_t espin_6;             // ESP input channel 6
  uint16_t espin_7;             // ESP input channel 7
  uint16_t espin_8;             // ESP input channel 8 
} espnow_data_send_t;

// Variable to store received ESP-NOW engine data
espnow_data_recv_t espnow_data_received;

// Variable for ESP-NOW ESPin data to send back
espnow_data_send_t espnow_data_to_send;

// Flag to indicate new data has been received
volatile bool espnow_data_available = false;

// ESP-NOW peer MAC address (main ESP32 device)
uint8_t espnow_receiver_mac[] = ESPNOW_RECEIVER_MAC;

// ESP-NOW send status
volatile bool espnow_send_ready = true;

// Ticker for periodic sending
Ticker espnow_send_ticker;

// Statistics
uint32_t packets_received = 0;
uint32_t packets_sent = 0;
uint32_t last_stats_time = 0;

// ESP-NOW connection monitoring
uint32_t last_espnow_packet_time = 0;
#define ESPNOW_TIMEOUT_MS 3000  // 3 seconds without data = connection lost

// END DATA
#if SCREEN
Adafruit_ST7789 tft = Adafruit_ST7789(&SPI, TFT_CS, TFT_DC, TFT_RST);
#endif

// ================= BLE SERVER =================
BLEServer *pServer = NULL;
BLECharacteristic *pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
Ticker bleUpdateTicker;

// BLE UUIDs - używamy standardowych
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE Client connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE Client disconnected");
    }
};
// ================= ESP-NOW CALLBACKS =================
// ESP-NOW send callback for ESP-IDF >= v5.0
extern "C" void onESPNowDataSent(const wifi_tx_info_t *info, esp_now_send_status_t status) {
  espnow_send_ready = true;
  if (status == ESP_NOW_SEND_SUCCESS) {
    packets_sent++;
  }
#if DEBUG
  else {
    Serial.println("ESP-NOW send failed!");
  }
#endif
}

// ESP-NOW receive callback for ESP-IDF >= v5.0
extern "C" void onESPNowDataReceived(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  if (len == sizeof(espnow_data_recv_t)) {
    memcpy(&espnow_data_received, incomingData, sizeof(espnow_data_recv_t));
    espnow_data_available = true;
    packets_received++;
    last_espnow_packet_time = millis();
    
#if DEBUG
    Serial.print("Received from: ");
    Serial.printf("%02X:%02X:%02X:%02X:%02X:%02X", 
                  recv_info->src_addr[0], recv_info->src_addr[1], 
                  recv_info->src_addr[2], recv_info->src_addr[3], 
                  recv_info->src_addr[4], recv_info->src_addr[5]);
    Serial.print(" | RPM: ");
    Serial.print(espnow_data_received.rpm);
    Serial.print(" | CLT: ");
    Serial.print(espnow_data_received.clt - 40);
    Serial.print("°C | TPS: ");
    {
      int tps_raw = espnow_data_received.tps;
      int tps_scaled = (int)(((tps_raw + TPS_OFFSET) * TPS_SCALE_NUMERATOR) / (float)TPS_SCALE_DENOMINATOR);
      if (tps_scaled < 0) tps_scaled = 0;
      if (tps_scaled > 100) tps_scaled = 100;
      Serial.print(tps_scaled);
    }
    Serial.println("%");
#endif
  }
#if DEBUG
  else {
    Serial.print("ESP-NOW data size mismatch: received ");
    Serial.print(len);
    Serial.print(" bytes, expected ");
    Serial.println(sizeof(espnow_data_recv_t));
  }
#endif
}

// ================= ESP-NOW INITIALIZATION =================
void initESPNow() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  
  Serial.print("ESP32 MAC Address: ");
  Serial.println(WiFi.macAddress());
  
  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW initialization failed!");
    return;
  }
  
  // Register callbacks
  esp_now_register_send_cb(onESPNowDataSent);
  esp_now_register_recv_cb(onESPNowDataReceived);
  
  // Add broadcast peer (or specific peer if configured)
  esp_now_peer_info_t peer_info = {};
  memcpy(peer_info.peer_addr, espnow_receiver_mac, 6);
  peer_info.channel = ESPNOW_CHANNEL;
  peer_info.encrypt = false;
  
  if (esp_now_add_peer(&peer_info) != ESP_OK) {
    Serial.println("ESP-NOW add peer failed!");
    return;
  }
  
  Serial.println("ESP-NOW initialized successfully!");
}

// ================= BLE INITIALIZATION =================
void initBLE() {
  BLEDevice::init("E46 Speeduino");
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  
  pCharacteristic->addDescriptor(new BLE2902());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE server started - waiting for connections...");
}

// ================= SEND DATA VIA BLE =================
void sendBLEData() {
  if (!deviceConnected) return;
  
  JsonDocument doc;
  
  // Conversions based on Serial3toBMWcan_ESP32_BASIC.ino sender code
  doc["rpm"] = espnow_data_received.rpm;  // Direct uint16_t
  doc["clt"] = espnow_data_received.clt - 40;  // CLT offset: 122 - 40 = 82°C ✓
  doc["iat"] = espnow_data_received.iat - 40;  // IAT offset: 26 - 40 = -14°C ✓
  doc["tps"] = espnow_data_received.tps / 2.0;  // TPS: 0-200 range / 2 = 0-100%: 86/2 = 43% ✓
  
  // MAP: Sender compresses with >> 2 (divide by 4), so we multiply by 4
  // espnow_data_to_send.map = (uint8_t)(currentStatus.MAP >> 2);
  int map_kpa = espnow_data_received.map * 4;  // 18 * 4 = 72 kPa (close to 74 with rounding)
  float map_abs_bar = map_kpa / 100.0;
  float map_gauge_bar = map_abs_bar - 1;
  doc["map"] = map_gauge_bar;

  doc["battery"] = espnow_data_received.battery / 10.0;  // battery10: /10 for volts
  
  // Advance: Speeduino sends as int8_t (already in degrees, can be negative)
  // currentStatus.advance is copied directly, just cast to signed
  doc["advance"] = (int8_t)espnow_data_received.advance;  // Cast to signed for negative values
  
  doc["pulsewidth"] = espnow_data_received.pulsewidth / 10.0;  // PW1: uint16 / 10 for ms
  doc["o2"] = espnow_data_received.o2 / 10.0;  // O2: /10 for AFR
  doc["boostDuty"] = espnow_data_received.boostDuty;  // Direct percentage (0-100)
  doc["boostTarget"] = espnow_data_received.boostTarget * 2 / 100.0;  // boostTarget * 2 kPa -> BAR
  
  // ESP-NOW connection status
  bool espnow_connected = (millis() - last_espnow_packet_time) < ESPNOW_TIMEOUT_MS;
  doc["espnowConnected"] = espnow_connected;
  doc["packetsReceived"] = packets_received;
  
  // Add warning thresholds
  doc["wrpm"] = WRPM;
  doc["wclt"] = WCLT;
  doc["wtps"] = WTPS;
  doc["wmap"] = WMAP;
  doc["wbattery"] = WBATTERY;
  doc["wadvance"] = WADVANCE;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  pCharacteristic->setValue(jsonString.c_str());
  pCharacteristic->notify();
}

// ================= DATA PROCESSING =================
void processReceivedData() {
  if (!espnow_data_available) {
    return;
  }
  
  // Here you can process received engine data and use it for your purposes
  // For example: display on LCD, log to SD card, control external devices, etc.
  
#if DEBUG
  // Display ALL received RAW data every second
  static uint32_t last_display = 0;
  if (millis() - last_display > 1000) {
    Serial.println("\n========== RAW Speeduino Data ==========");
    Serial.print("Timestamp: "); Serial.println(espnow_data_received.timestamp);
    Serial.print("RPM: "); Serial.println(espnow_data_received.rpm);
    Serial.print("CLT (raw): "); Serial.println(espnow_data_received.clt);
    Serial.print("IAT (raw): "); Serial.println(espnow_data_received.iat);
    Serial.print("TPS (raw): "); Serial.println(espnow_data_received.tps);
    Serial.print("MAP (raw): "); Serial.println(espnow_data_received.map);
    Serial.print("Battery (raw): "); Serial.println(espnow_data_received.battery);
    Serial.print("O2 (raw): "); Serial.println(espnow_data_received.o2);
    Serial.print("Advance (raw): "); Serial.println(espnow_data_received.advance);
    Serial.print("Pulsewidth (raw): "); Serial.println(espnow_data_received.pulsewidth);
    Serial.print("Boost Duty (raw): "); Serial.println(espnow_data_received.boostDuty);
    Serial.print("Boost Target (raw): "); Serial.println(espnow_data_received.boostTarget);
    Serial.print("Status Flags: 0x"); Serial.println(espnow_data_received.statusFlags, HEX);
    Serial.print("Error Flags: 0x"); Serial.println(espnow_data_received.errorFlags, HEX);
    Serial.println("========================================");
    last_display = millis();
  }
#endif
  
  // Clear the flag
  espnow_data_available = false;
}

// ================= PREPARE ESPin DATA =================
void prepareESPinData() {
  // Here you can set ESPin values from sensors, CAN bus, serial, or other sources
  // For now, we'll use default values or keep previous values
  
  // Example: Set some test values or read from sensors
  // espnow_data_to_send.espin_1 = analogRead(A0);
  // espnow_data_to_send.espin_2 = digitalRead(PIN) * 1000;
  // etc...
  
  // For demonstration, we'll keep default values
  // In real application, replace this with actual sensor readings
}

// ================= SEND ESPin DATA =================
void onESPNowSendTimer() {
  if (!espnow_send_ready) {
    return; // Previous send still in progress
  }
  
  // Prepare ESPin data (read sensors, calculate values, etc.)
  prepareESPinData();
  
  // Send data via ESP-NOW
  espnow_send_ready = false;
  esp_err_t result = esp_now_send(espnow_receiver_mac, (uint8_t *) &espnow_data_to_send, sizeof(espnow_data_to_send));
  
#if DEBUG
  if (result != ESP_OK) {
    Serial.print("ESP-NOW send error: ");
    Serial.println(result);
    espnow_send_ready = true; // Reset for retry
  }
#endif
}

// ================= STATISTICS =================
void displayStats() {
  if (millis() - last_stats_time > 5000) {
    Serial.println("\n===== ESP-NOW Statistics =====");
    Serial.print("Packets received: ");
    Serial.println(packets_received);
    Serial.print("Packets sent: ");
    Serial.println(packets_sent);
    Serial.println("==============================\n");
    last_stats_time = millis();
  }
}








// ================= SETUP =================
void setup() {
  // Initialize Serial
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n====================================");
  Serial.println("ESP32-SENDER starting...");
  Serial.println("Version date: 20.8.2025");
  Serial.print("ESP32 MAC Address: ");    // Display ESP32 MAC Address
  Serial.println(WiFi.macAddress());    // Display ESP32 MAC Address
  Serial.println("====================================");
  // Initialize ESP-NOW

  // Initialize ESP-NOW
  initESPNow();
  
  // Initialize BLE
  initBLE();
  
  // Start periodic BLE data sending
  bleUpdateTicker.attach(0.1, sendBLEData);  // 10Hz update rate

  // Initialize SCREEN
#if SCREEN
  pinMode(BLK_PIN, OUTPUT);
  digitalWrite(BLK_PIN, HIGH);
  pinMode(TFT_RST, OUTPUT);
  digitalWrite(TFT_RST, LOW);
  delay(50);
  digitalWrite(TFT_RST, HIGH);
  delay(50);
  tft.init(170, 320);
  tft.setRotation(1);
  tft.fillScreen(ST77XX_BLACK);
  delay(500);
#endif

  // Initialize ESPin data with default values (only 1-8 channels)
  espnow_data_to_send.espin_1 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_2 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_3 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_4 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_5 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_6 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_7 = DEFAULT_ESPIN_VALUE;
  espnow_data_to_send.espin_8 = DEFAULT_ESPIN_VALUE;
  
  // Start periodic ESPin data sending
  espnow_send_ticker.attach(1.0 / ESPNOW_DATA_SEND_RATE, onESPNowSendTimer);
  
  Serial.println("ESP32-SENDER initialized successfully!");
  Serial.println("Waiting for data from main ESP32...\n");
}

// ================= MAIN LOOP =================
void loop() {
  // Handle BLE connection state
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  // Process received engine data
  processReceivedData();
  
  // Display statistics periodically
#if DEBUG
  displayStats();
#endif
  
  // Add your custom code here
  // For example: read sensors, control outputs, etc.
  
  delay(10); // Small delay to prevent watchdog issues
}
