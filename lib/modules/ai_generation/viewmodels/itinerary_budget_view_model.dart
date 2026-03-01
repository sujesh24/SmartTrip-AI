class ItineraryBudgetViewModel {
  String? validateBudget(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your estimated budget.';
    }

    final int? value = int.tryParse(trimmed);
    if (value == null || value <= 0) {
      return 'Please enter a valid budget amount.';
    }

    return null;
  }
}
