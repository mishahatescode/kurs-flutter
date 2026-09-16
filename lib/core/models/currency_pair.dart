/// A source → target pairing, as recorded in the recent-pairs list.
class CurrencyPair {
  const CurrencyPair(this.from, this.to);

  final String from;
  final String to;

  @override
  bool operator ==(Object other) =>
      other is CurrencyPair && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  Map<String, dynamic> toJson() => {'from': from, 'to': to};

  static CurrencyPair fromJson(Map<String, dynamic> json) =>
      CurrencyPair(json['from'] as String, json['to'] as String);

  @override
  String toString() => '$from→$to';
}
