/// Server-issued current admin rates. Missing API key is legacy; explicit null disables decay.
class CurrentDecayPolicy {
  CurrentDecayPolicy._(
    this.revision,
    this.rates,
    this.floor,
    this.elapsedCapSeconds,
  );
  final String revision;
  final double floor;
  final int elapsedCapSeconds;
  final Map<String, Map<String, double>> rates;
  static const units = {
    'egg': 1,
    'child': 1,
    'training': 3600,
    'growth': 3600,
    'first_team': 3600,
  };
  static const parameters = ['hunger', 'cleanliness', 'condition', 'work'];
  static CurrentDecayPolicy? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map ||
        raw['schema'] != 1 ||
        raw['revision'] is! String ||
        (raw['revision'] as String).isEmpty ||
        raw['rates'] is! Map ||
        raw['seconds_per_unit'] is! Map) {
      throw const FormatException('Unsupported cycle decay policy');
    }
    if (raw['floor'] is! num ||
        !(raw['floor'] as num).isFinite ||
        raw['floor'] < 0 ||
        raw['floor'] > 100 ||
        raw['elapsed_cap_seconds'] is! int ||
        raw['elapsed_cap_seconds'] <= 0)
      throw const FormatException('Invalid decay bounds');
    final values = <String, Map<String, double>>{};
    for (final stage in units.keys) {
      if (raw['seconds_per_unit'][stage] != units[stage] ||
          raw['rates'][stage] is! Map)
        throw const FormatException('Invalid decay unit');
      values[stage] = {};
      for (final name in parameters) {
        final v = raw['rates'][stage][name];
        if (v is! num || !v.isFinite || v < 0)
          throw const FormatException('Invalid decay rate');
        values[stage]![name] = v.toDouble();
      }
      values[stage] = Map.unmodifiable(values[stage]!);
    }
    return CurrentDecayPolicy._(
      raw['revision'] as String,
      Map.unmodifiable(values),
      (raw['floor'] as num).toDouble(),
      raw['elapsed_cap_seconds'] as int,
    );
  }

  /// Split the interval at 100 rather than doubling the whole interval.
  double after(
    String stage,
    String name,
    double value,
    int seconds,
    double floor,
  ) {
    if (seconds <= 0 || value <= floor) return value;
    final rate = rates[stage]![name]!;
    if (rate == 0) return value;
    final elapsed = seconds.clamp(0, elapsedCapSeconds) / units[stage]!;
    final excessUnits = value > 100
        ? ((value - 100) / (rate * 2)).clamp(0, elapsed).toDouble()
        : 0.0;
    return (value - rate * (elapsed + excessUnits))
        .clamp(floor, 150)
        .toDouble();
  }
}
