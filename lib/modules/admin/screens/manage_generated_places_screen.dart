import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ManageGeneratedPlacesScreen extends StatefulWidget {
  const ManageGeneratedPlacesScreen({super.key});

  @override
  State<ManageGeneratedPlacesScreen> createState() =>
      _ManageGeneratedPlacesScreenState();
}

class _ManageGeneratedPlacesScreenState
    extends State<ManageGeneratedPlacesScreen> {
  String _sortBy = 'newest';
  int _refreshVersion = 0;

  Future<void> _refreshGeneratedPlaces() async {
    if (!mounted) {
      return;
    }

    setState(() => _refreshVersion += 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Generated Places',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SortChip(
                    label: 'Newest',
                    isSelected: _sortBy == 'newest',
                    onPressed: () => setState(() => _sortBy = 'newest'),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SortChip(
                    label: 'Most Generated',
                    isSelected: _sortBy == 'mostGenerated',
                    onPressed: () => setState(() => _sortBy = 'mostGenerated'),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshGeneratedPlaces,
              color: primaryTextColor,
              child: _buildGeneratedPlacesList(
                primaryTextColor: primaryTextColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPlacesList({
    required Color primaryTextColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey<String>('$_sortBy-$_refreshVersion'),
      stream: FirebaseFirestore.instance
          .collection('generated_places')
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              debugPrint('Generated places load error: ${snapshot.error}');
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  Center(
                    child: Text(
                      'Error loading generated places.',
                      style: TextStyle(color: primaryTextColor),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final List<_GeneratedPlaceSummary> places = docs
                .map(_GeneratedPlaceSummary.fromDocument)
                .toList();
            _sortGeneratedPlaces(places);

            if (places.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  Center(
                    child: Text(
                      'No generated places yet.',
                      style: TextStyle(color: primaryTextColor),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: places.length,
              itemBuilder: (BuildContext context, int index) {
                final _GeneratedPlaceSummary place = places[index];
                final String latestTime = place.latestActivityAt == null
                    ? 'Unknown'
                    : _formatTimestamp(place.latestActivityAt!);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderColor),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryTextColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.public_rounded,
                        color: primaryTextColor,
                      ),
                    ),
                    title: Text(
                      place.placeName,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Generated ${_countLabel(place.generationCount)} - '
                      'Saved ${_countLabel(place.savedCount)} - '
                      'Latest: $latestTime\n'
                      'Latest user: ${place.lastUserLabel}',
                      style: TextStyle(
                        color: primaryTextColor.withValues(alpha: 0.7),
                        fontFamily: 'Times New Roman',
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ),
                );
              },
            );
          },
    );
  }

  void _sortGeneratedPlaces(List<_GeneratedPlaceSummary> places) {
    places.sort((_GeneratedPlaceSummary first, _GeneratedPlaceSummary second) {
      if (_sortBy == 'mostGenerated') {
        final int countCompare = second.generationCount.compareTo(
          first.generationCount,
        );
        if (countCompare != 0) {
          return countCompare;
        }
      }

      final DateTime firstDate =
          first.latestActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondDate =
          second.latestActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondDate.compareTo(firstDate);
    });
  }

  String _countLabel(int count) {
    return '$count time${count == 1 ? '' : 's'}';
  }

  String _formatTimestamp(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class _GeneratedPlaceSummary {
  const _GeneratedPlaceSummary({
    required this.placeName,
    required this.generationCount,
    required this.savedCount,
    required this.lastGeneratedAt,
    required this.lastSavedAt,
    required this.updatedAt,
    required this.lastUserId,
    required this.lastUserEmail,
  });

  final String placeName;
  final int generationCount;
  final int savedCount;
  final DateTime? lastGeneratedAt;
  final DateTime? lastSavedAt;
  final DateTime? updatedAt;
  final String lastUserId;
  final String lastUserEmail;

  DateTime? get latestActivityAt {
    final List<DateTime> dates = <DateTime>[
      if (lastGeneratedAt != null) lastGeneratedAt!,
      if (lastSavedAt != null) lastSavedAt!,
      if (updatedAt != null) updatedAt!,
    ];
    if (dates.isEmpty) {
      return null;
    }
    dates.sort((DateTime first, DateTime second) => second.compareTo(first));
    return dates.first;
  }

  String get lastUserLabel {
    if (lastUserEmail.isNotEmpty) {
      return lastUserEmail;
    }
    if (lastUserId.isNotEmpty) {
      return lastUserId;
    }
    return 'Unknown';
  }

  factory _GeneratedPlaceSummary.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final String placeName = _readString(data['placeName']);

    return _GeneratedPlaceSummary(
      placeName: placeName.isEmpty ? document.id : placeName,
      generationCount: _readInt(data['generationCount']),
      savedCount: _readInt(data['savedCount']),
      lastGeneratedAt: _readDate(data['lastGeneratedAt']),
      lastSavedAt: _readDate(data['lastSavedAt']),
      updatedAt: _readDate(data['updatedAt']),
      lastUserId: _readString(data['lastUserId']),
      lastUserEmail: _readString(data['lastUserEmail']),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    required this.primaryTextColor,
    required this.borderColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color primaryTextColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryTextColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryTextColor : borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
