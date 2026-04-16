class RequestQuote {
  const RequestQuote({
    required this.distanceKm,
    required this.etaMinutes,
    required this.estimatedPriceDzd,
    required this.breakdown,
  });

  final double distanceKm;
  final int etaMinutes;
  final int estimatedPriceDzd;
  final List<String> breakdown;
}