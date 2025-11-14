class EngineData {
  final int rpm;
  final int clt; // Coolant °C
  final int iat; // Intake °C
  final int tps; // %
  final int map; // kPa
  final double battery; // V
  final int advance; // °
  final double pulsewidth; // ms
  final double o2; // AFR
  final int boostDuty; // %
  final int boostTarget; // kPa

  // Warning thresholds
  final int wrpm;
  final int wclt;
  final int wtps;
  final int wmap;
  final int wadvance;

  const EngineData({
    required this.rpm,
    required this.clt,
    required this.iat,
    required this.tps,
    required this.map,
    required this.battery,
    required this.advance,
    required this.pulsewidth,
    required this.o2,
    required this.boostDuty,
    required this.boostTarget,
    required this.wrpm,
    required this.wclt,
    required this.wtps,
    required this.wmap,
    required this.wadvance,
  });

  static const empty = EngineData(
    rpm: 0,
    clt: 0,
    iat: 0,
    tps: 0,
    map: 0,
    battery: 0.0,
    advance: 0,
    pulsewidth: 0.0,
    o2: 0.0,
    boostDuty: 0,
    boostTarget: 0,
    wrpm: 6800,
    wclt: 95,
    wtps: 95,
    wmap: 250,
    wadvance: 35,
  );

  factory EngineData.fromJson(Map<String, dynamic> j) {
    num toNum(v, [num d = 0]) => v is num ? v : num.tryParse('$v') ?? d;
    int toInt(v, [int d = 0]) => toNum(v, d).toInt();
    double toDouble(v, [double d = 0]) => toNum(v, d).toDouble();

    return EngineData(
      rpm: toInt(j['rpm']),
      clt: toInt(j['clt']),
      iat: toInt(j['iat']),
      tps: toInt(j['tps']),
      map: toInt(j['map']),
      battery: toDouble(j['battery']),
      advance: toInt(j['advance']),
      pulsewidth: toDouble(j['pulsewidth']),
      o2: toDouble(j['o2']),
      boostDuty: toInt(j['boostDuty']),
      boostTarget: toInt(j['boostTarget']),
      wrpm: toInt(j['wrpm'], empty.wrpm),
      wclt: toInt(j['wclt'], empty.wclt),
      wtps: toInt(j['wtps'], empty.wtps),
      wmap: toInt(j['wmap'], empty.wmap),
      wadvance: toInt(j['wadvance'], empty.wadvance),
    );
  }
}
