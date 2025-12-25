class ReviewIntervals {
  // Gün cinsinden tekrar aralıkları: 1-3-7-14-30-60
  static const List<int> days = [1, 3, 7, 14, 30, 60];

  static int clampIndex(int index) {
    if (index < 0) return 0;
    if (index >= days.length) return days.length - 1;
    return index;
  }
}
