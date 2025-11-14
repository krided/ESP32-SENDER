# E46 Speeduino iOS App - Setup Instructions

## Overview
This iOS app connects to your ESP32 via Bluetooth Low Energy (BLE) to display real-time engine data from your Speeduino ECU. The app design matches exactly the web interface you created earlier.

## Prerequisites
- macOS with Xcode 14.0 or later
- iPhone running iOS 15.0 or later
- Apple Developer account (for device deployment)

## Xcode Project Setup

### 1. Create New Xcode Project
1. Open Xcode
2. Select **File > New > Project**
3. Choose **iOS** platform
4. Select **App** template
5. Click **Next**

### 2. Configure Project Settings
- **Product Name**: `E46SpeeduinoApp`
- **Team**: Select your Apple Developer team
- **Organization Identifier**: Use your reverse domain (e.g., `com.yourname`)
- **Bundle Identifier**: Will be `com.yourname.E46SpeeduinoApp`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None
- Click **Next** and choose save location

### 3. Add Source Files
1. In Xcode Project Navigator, delete the default `ContentView.swift` file
2. Right-click on the project folder and select **Add Files to "E46SpeeduinoApp"**
3. Add these files from the `iOS-App` directory:
   - `E46SpeeduinoApp.swift` (replace the default one)
   - `ContentView.swift`
   - `BLEManager.swift`
4. Make sure **Copy items if needed** is checked

### 4. Configure Info.plist
1. Select `Info.plist` in Project Navigator
2. Delete the default file
3. Add the `Info.plist` from the `iOS-App` directory
4. Or manually add these keys:
   - **NSBluetoothAlwaysUsageDescription**: "This app needs Bluetooth to connect to your E46 Speeduino engine monitor"
   - **NSBluetoothPeripheralUsageDescription**: "This app needs Bluetooth to connect to your E46 Speeduino engine monitor"

### 5. Set Deployment Target
1. Select your project in Project Navigator
2. Select your target
3. In **General** tab, set **Minimum Deployments** to **iOS 15.0**

### 6. Configure Signing
1. In **Signing & Capabilities** tab
2. Check **Automatically manage signing**
3. Select your **Team**
4. Xcode will generate a Provisioning Profile

## ESP32 Configuration

### 1. Install Required Libraries
Install these libraries via Arduino Library Manager:
- **ArduinoJson** (version 6.x)
- **ESP32 BLE Arduino** (included in ESP32 board support)

### 2. Upload Firmware
1. Open `ESP32-SENDER.ino` in Arduino IDE
2. Select **Board**: ESP32 Dev Module
3. Select correct **Port**
4. Click **Upload**
5. Monitor Serial output (115200 baud) to verify BLE initialization

### 3. Verify BLE Service
The ESP32 will advertise as **"E46 Speeduino"** with:
- Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

## Running the App

### 1. Connect iPhone
1. Connect your iPhone via USB
2. Trust the computer if prompted
3. In Xcode, select your iPhone as the destination

### 2. Build and Run
1. Click the **Play** button in Xcode (or press **Cmd+R**)
2. On first launch, your iPhone will prompt for Bluetooth permission - **Allow**
3. The app will automatically scan for "E46 Speeduino" BLE device

### 3. Connection Process
- When ESP32 is powered on, the app will show **"Scanning..."**
- Once connected, status changes to **"Connected"** with green indicator
- Engine data updates every 100ms (10Hz)
- If connection is lost, app automatically reconnects

## Features

### Real-time Gauges
- **RPM**: Engine speed in rev/min
- **Coolant**: Temperature in °C
- **Throttle**: Position in %
- **MAP**: Manifold pressure in BAR (converted from kPa)
- **Battery**: Voltage in V
- **Advance**: Ignition timing in degrees

### Info Section
- **IAT**: Intake Air Temperature
- **Pulse Width**: Injector duration in ms
- **AFR**: Air-Fuel Ratio from O2 sensor
- **Boost Duty**: Boost control duty cycle %
- **Boost Target**: Target boost in BAR

### Warning System
Gauges turn red with pulsing animation when values exceed thresholds defined in `Config.h`:
- `WRPM`: RPM warning (default 6800)
- `WCLT`: Coolant warning (default 95°C)
- `WTPS`: Throttle warning (default 95%)
- `WMAP`: MAP warning (default 250 kPa)
- `WADVANCE`: Advance warning

## Troubleshooting

### App doesn't find ESP32
1. Verify ESP32 is powered on
2. Check Serial Monitor for "BLE server started" message
3. Go to iPhone **Settings > Bluetooth** - you should see "E46 Speeduino"
4. Kill and restart the app
5. Check BLE UUIDs match between ESP32 and iOS code

### No data displayed
1. Check BLE connection status indicator (should be green)
2. Verify ESP-NOW is receiving data from main Speeduino ESP32
3. Check Serial Monitor for JSON output every 100ms
4. Restart both ESP32 and app

### Connection keeps dropping
1. Keep iPhone within 10m of ESP32
2. Avoid obstacles between devices
3. Check for BLE interference from other devices
4. Verify ESP32 power supply is stable

### Build errors in Xcode
1. Ensure iOS Deployment Target is 15.0 or higher
2. Check that all files are added to target membership
3. Clean build folder: **Product > Clean Build Folder** (Cmd+Shift+K)
4. Restart Xcode

## Customization

### Warning Thresholds
Edit `Config.h` on ESP32 to change warning values:
```cpp
#define WRPM 6800      // RPM warning threshold
#define WCLT 95        // Coolant temp warning (°C)
#define WTPS 95        // Throttle position warning (%)
#define WMAP 250       // MAP warning (kPa)
#define WADVANCE 35    // Advance warning (degrees)
```

### Colors and Design
Edit `ContentView.swift` to customize:
- Background gradient colors
- Border colors
- Warning animation timing
- Font sizes and styles

### Update Rate
Change BLE update frequency in `ESP32-SENDER.ino`:
```cpp
bleUpdateTicker.attach(0.1, sendBLEData); // 0.1 = 10Hz, 0.05 = 20Hz
```

## Architecture

### Data Flow
1. Speeduino ESP32 → ESP-NOW → Receiver ESP32
2. Receiver ESP32 → JSON serialization → BLE Notification
3. iPhone BLE → JSON decode → SwiftUI View update

### BLE Protocol
- Notifications enabled for automatic updates
- JSON format for all engine parameters
- Auto-reconnection on disconnect
- No pairing required

## Support
If you encounter issues:
1. Check Serial Monitor output from ESP32
2. Enable Xcode console output to see BLE logs
3. Verify all UUIDs match between ESP32 and iOS
4. Ensure iOS Bluetooth permissions are granted
