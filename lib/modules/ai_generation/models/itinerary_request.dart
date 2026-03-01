class ItineraryRequest {
  ItineraryRequest({
    this.destination = '',
    this.startDate = '',
    this.endDate = '',
    this.companion = '',
    List<String>? interests,
    this.budget = '',
  }) : interests = interests ?? <String>[];

  String destination;
  String startDate;
  String endDate;
  String companion;
  List<String> interests;
  String budget;
}
