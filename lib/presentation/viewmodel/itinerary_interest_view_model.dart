import 'package:smarttrip_ai/presentation/model/interest_option.dart';

class ItineraryInterestViewModel {
  final Set<InterestOption> _selected = <InterestOption>{};

  List<InterestOption> get options => InterestOption.values;

  bool isSelected(InterestOption option) => _selected.contains(option);

  void toggle(InterestOption option) {
    if (_selected.contains(option)) {
      _selected.remove(option);
      return;
    }
    _selected.add(option);
  }

  String? validateBeforeNext() {
    if (_selected.isEmpty) {
      return 'Please select at least one interest.';
    }
    return null;
  }
}
