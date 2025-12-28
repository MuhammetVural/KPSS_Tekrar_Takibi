class ReviewIntervals {
  static const List<int> easy = [1, 3, 7, 14, 30, 60];
  static const List<int> medium = [1, 2, 4, 7, 14, 30];
  static const List<int> hard = [1, 1, 2, 4, 7, 14];

  static List<int> daysForDifficulty(int difficulty) {
    switch (difficulty) {
      case 0: return easy;
      case 2: return hard;
      case 1:
      default: return medium;
    }
  }

  static int clampIndex(int index, {int length = 6}) {
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }
}