class ReviewIntervals {
  // CUMULATIVE günler (Gün 0 dahil)
  // 0: konu+soru bitti
  // 1: 1. tekrar
  // 3: 2. tekrar
  // 7: 3. tekrar
  // 21: 4. tekrar
  // 30: 5. tekrar
  static const List<int> medium = [0, 1, 3, 7, 21, 30];

  // Difficulty istersen burada farklılaştır (şimdilik medium ile aynı bırakabilirsin)
  static const List<int> easy = [0, 1, 4, 9, 21, 30];
  static const List<int> hard = [0, 1, 2, 4, 7, 14, 21, 30];

  static List<int> daysForDifficulty(int difficulty) {
    switch (difficulty) {
      case 0:
        return easy;
      case 2:
        return hard;
      case 1:
      default:
        return medium;
    }
  }

  static int clampIndex(int index, {int? length}) {
    // length yoksa sadece negatifi kırp (geriye dönük uyumluluk)
    if (length == null) return index < 0 ? 0 : index;

    if (length <= 0) return 0;
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }

  /// currentIdx -> nextIdx arası KAÇ GÜN?
  static int gapDays(List<int> cumulative, int currentIdx, int nextIdx) {
    if (cumulative.isEmpty) return 0;
    final c = clampIndex(currentIdx, length: cumulative.length);
    final n = clampIndex(nextIdx, length: cumulative.length);
    final diff = (cumulative[n] - cumulative[c]).abs();
    return diff <= 0 ? 0 : diff;
  }
}