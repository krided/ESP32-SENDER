// Configuration file for ESP32-SENDER
// This device receives engine data via ESP-NOW and sends ESPin data back

#ifndef CONFIG_H
#define CONFIG_H

// ================= ESP-NOW CONFIGURATION =================
#define ESPNOW_ENABLED 1                    // Enable ESP-NOW communication
#define ESPNOW_CHANNEL 1                    // WiFi channel (must match receiver)
#define ESPNOW_DATA_SEND_RATE 20           // Send rate in Hz for ESPin data

// MAC address of the main ESP32 (Serial3toBMW device)
// Replace with actual MAC address shown on serial monitor of main device
#define ESPNOW_RECEIVER_MAC {0x88, 0x57, 0x21, 0x79, 0xEC, 0xC4}  // Broadcast or specific MAC

// ================= DEBUG CONFIGURATION =================
#define DEBUG 0                             // Enable debug output to serial

// ================= WEB SERVER CONFIGURATION =================
#define WEB_SERVER_ENABLED 1                // Enable web server for iPhone access
#define WEB_SERVER_PORT 80                  // HTTP port
#define WEBSOCKET_ENABLED 1                 // Enable WebSocket for real-time data
#define WEB_UPDATE_RATE 10                  // Web data update rate in Hz

// iPhone Hotspot WiFi credentials
#define WIFI_SSID "iPazdan"                  // Your iPhone hotspot name
#define WIFI_PASSWORD "michal22"       // Your iPhone hotspot password
#define WIFI_TIMEOUT 15000                  // WiFi connection timeout (ms)

// mDNS hostname (access via http://HOSTNAME.local)
#define MDNS_HOSTNAME "lysyze46"        // Change to your preferred name (no spaces, no .local)

// ================= ESP INPUT CHANNELS =================
// You can set default values or read from sensors/CAN/serial
#define DEFAULT_ESPIN_VALUE 0               // Default value for ESPin channels

// ================= SENSOR SCALING/CALIBRATION =================
// TPS reported by the main ESP32 may differ from TunerStudio scaling.
// Use these to correct the displayed TPS value without touching sender firmware.
// Example: if TunerStudio shows 20% and here shows 40%, set denominator to 2.
#define TPS_OFFSET            0             // Additive offset in percent before scaling (usually 0)
#define TPS_SCALE_NUMERATOR   1             // Numerator for scaling (usually 1)
#define TPS_SCALE_DENOMINATOR 2             // Denominator for scaling (set to 2 to halve)

// ==================  SCREEN ===========================
#define SCREEN  0                           // Enable TFT screen support (1 = enabled, 0 = disabled)
#define TFT_MOSI 23
#define TFT_SCLK 18
#define TFT_CS   5
#define TFT_DC   16
#define TFT_RST  17
#define BLK_PIN  27

// ================= DATA WARNINGS =================
// Warning thresholds for engine parameters
#define WRPM          6800        // Engine RPM warning threshold
#define WPULSEWIDTH   15          // Fuel injection pulse width warning (ms)
#define WCLT          95          // Coolant temperature warning (°C)
#define WIAT          60          // Intake air temperature warning (°C)
#define WTPS          95          // Throttle position warning (%)
#define WMAP          250         // Manifold absolute pressure warning (kPa internally, displayed as 2.50 bar)
#define WBATTERY      15          // Battery voltage warning (V * 10, e.g., 150 = 15.0V)
#define WO2           900         // Oxygen sensor warning (AFR * 10, e.g., 900 = 9.0 AFR)
#define WADVANCE      35          // Ignition advance warning (degrees)
#define WBOOST_DUTY   90          // Boost duty warning (%)
#define WBOOST_TARGET 200         // Boost target warning (kPa internally, displayed as 2.00 bar)

#endif // CONFIG_H
