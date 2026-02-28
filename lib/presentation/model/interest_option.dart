enum InterestOption { historicLandmarks, deliciousFoods, artGalleries, hiking }

extension InterestOptionLabel on InterestOption {
  String get label {
    switch (this) {
      case InterestOption.historicLandmarks:
        return 'Historic Landmarks';
      case InterestOption.deliciousFoods:
        return 'Delicious Foods';
      case InterestOption.artGalleries:
        return 'Art Galleries';
      case InterestOption.hiking:
        return 'Hiking';
    }
  }
}
