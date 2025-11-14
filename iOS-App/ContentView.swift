import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "000001"), Color(hex: "001336")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    // Header
                    VStack(spacing: 5) {
                        Text("Engine Monitor")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            Circle()
                                .fill(bleManager.isConnected ? Color(hex: "15A449") : Color(hex: "FC0000"))
                                .frame(width: 8, height: 8)
                            Text(bleManager.connectionStatus)
                                .font(.caption)
                                .foregroundColor(bleManager.isConnected ? Color(hex: "15A449") : Color(hex: "FC0000"))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Gauges Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        GaugeView(
                            label: "RPM",
                            value: "\(bleManager.engineData.rpm)",
                            unit: "rev/min",
                            isWarning: bleManager.engineData.rpm >= bleManager.engineData.wrpm
                        )
                        
                        GaugeView(
                            label: "COOLANT",
                            value: "\(bleManager.engineData.clt)",
                            unit: "°C",
                            isWarning: bleManager.engineData.clt >= bleManager.engineData.wclt
                        )
                        
                        GaugeView(
                            label: "THROTTLE",
                            value: "\(bleManager.engineData.tps)",
                            unit: "%",
                            isWarning: bleManager.engineData.tps >= bleManager.engineData.wtps
                        )
                        
                        GaugeView(
                            label: "MAP",
                            value: String(format: "%.2f", Double(bleManager.engineData.map) / 100.0),
                            unit: "BAR",
                            isWarning: bleManager.engineData.map >= bleManager.engineData.wmap
                        )
                        
                        GaugeView(
                            label: "BATTERY",
                            value: bleManager.engineData.battery,
                            unit: "V",
                            isWarning: false
                        )
                        
                        GaugeView(
                            label: "ADVANCE",
                            value: "\(bleManager.engineData.advance)",
                            unit: "°",
                            isWarning: bleManager.engineData.advance >= bleManager.engineData.wadvance
                        )
                    }
                    .padding(.horizontal, 10)
                    
                    // Info Section
                    VStack(spacing: 0) {
                        InfoRow(label: "IAT:", value: "\(bleManager.engineData.iat)°C")
                        InfoRow(label: "Pulse Width:", value: "\(bleManager.engineData.pulsewidth) ms")
                        InfoRow(label: "AFR:", value: "\(bleManager.engineData.o2)")
                        InfoRow(label: "Boost Duty:", value: "\(bleManager.engineData.boostDuty)%")
                        InfoRow(label: "Boost Target:", value: String(format: "%.2f BAR", Double(bleManager.engineData.boostTarget) / 100.0), isLast: true)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.33))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "11E00F").opacity(0.77), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct GaugeView: View {
    let label: String
    let value: String
    let unit: String
    let isWarning: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .textCase(.uppercase)
                .kerning(1)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWarning ? Color(hex: "F10000").opacity(0.88) : Color.black.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWarning ? Color(hex: "B60000") : Color(hex: "0AFF00").opacity(0.62), lineWidth: 1)
                )
        )
        .opacity(isWarning ? (Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1) > 0.5 ? 1 : 0.7) : 1)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isLast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            
            if !isLast {
                Divider()
                    .background(Color(hex: "08CC00").opacity(0.8))
                    .padding(.horizontal, 15)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
