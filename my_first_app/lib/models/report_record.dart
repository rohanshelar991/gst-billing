class MonthlyRevenuePoint {
  const MonthlyRevenuePoint({
    required this.monthKey,
    required this.totalRevenue,
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.growthPercent,
  });

  final String monthKey;
  final double totalRevenue;
  final double paidRevenue;
  final double unpaidRevenue;
  final double growthPercent;
}

class GstSummaryRecord {
  const GstSummaryRecord({
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalTax,
    required this.taxableAmount,
  });

  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;
  final double taxableAmount;

  double get taxPayable => totalTax;
}

class TopClientRecord {
  const TopClientRecord({
    required this.clientId,
    required this.clientName,
    required this.invoiceCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
  });

  final String clientId;
  final String clientName;
  final int invoiceCount;
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
}
