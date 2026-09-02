// Help-request prices are shown in Egyptian pounds (LE).

String? formatOfferPriceLe(double? price) {
  if (price == null) return null;
  final whole = price % 1 < 1e-6;
  final s = whole ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  return '$s LE';
}
