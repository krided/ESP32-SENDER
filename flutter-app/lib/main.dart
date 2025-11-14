import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble/ble_manager.dart';
import 'model/engine_data.dart';
import 'ui/widgets/gauge_card.dart';
import 'ui/widgets/info_row.dart';

void main() {
  runApp(const E46App());
}

class E46App extends StatelessWidget {
  const E46App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleManager(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'E46 Speeduino',
        theme: ThemeData(fontFamily: 'SF Pro'),
        home: const DashboardPage(),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final d = ble.data;

    final gradient = const LinearGradient(
      colors: [Color(0xFF000001), Color(0xFF001336)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Text(
                        'Engine Monitor',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ble.isConnected ? const Color(0xFF15A449) : const Color(0xFFFC0000),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ble.status,
                            style: TextStyle(
                              color: ble.isConnected ? const Color(0xFF15A449) : const Color(0xFFFC0000),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Gauges grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  delegate: SliverChildListDelegate([
                    GaugeCard(
                      label: 'RPM',
                      value: '${d.rpm}',
                      unit: 'rev/min',
                      warning: d.rpm >= d.wrpm,
                    ),
                    GaugeCard(
                      label: 'COOLANT',
                      value: '${d.clt}',
                      unit: '°C',
                      warning: d.clt >= d.wclt,
                    ),
                    GaugeCard(
                      label: 'THROTTLE',
                      value: '${d.tps}',
                      unit: '%',
                      warning: d.tps >= d.wtps,
                    ),
                    GaugeCard(
                      label: 'MAP',
                      value: (d.map / 100).toStringAsFixed(2),
                      unit: 'BAR',
                      warning: d.map >= d.wmap,
                    ),
                    GaugeCard(
                      label: 'BATTERY',
                      value: d.battery.toStringAsFixed(1),
                      unit: 'V',
                      warning: false,
                    ),
                    GaugeCard(
                      label: 'ADVANCE',
                      value: '${d.advance}',
                      unit: '°',
                      warning: d.advance >= d.wadvance,
                    ),
                  ]),
                ),
              ),

              // Info section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x54000000), // black 33%
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xC411E00F), width: 1),
                    ),
                    child: Column(
                      children: [
                        InfoRow(label: 'IAT:', value: '${d.iat}°C'),
                        InfoRow(label: 'Pulse Width:', value: '${d.pulsewidth.toStringAsFixed(2)} ms'),
                        InfoRow(label: 'AFR:', value: d.o2.toStringAsFixed(2)),
                        InfoRow(label: 'Boost Duty:', value: '${d.boostDuty}%'),
                        InfoRow(label: 'Boost Target:', value: '${(d.boostTarget / 100).toStringAsFixed(2)} BAR', isLast: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
