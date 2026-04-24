class HomeDestination {
  const HomeDestination({
    required this.id,
    required this.name,
    required this.flag,
    required this.description,
    required this.bestTime,
    required this.budget,
    required this.rating,
    required this.pexelsQuery,
    this.showOnHome = true,
  });

  final String id;
  final String name;
  final String flag;
  final String description;
  final String bestTime;
  final String budget;
  final double rating;
  final String pexelsQuery;
  final bool showOnHome;

  String get displayName => '$flag $name';
}

String homeDestinationHeroTag(String destinationId) =>
    'home-destination-hero-$destinationId';
