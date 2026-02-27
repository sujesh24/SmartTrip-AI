import 'package:flutter/material.dart';

class ItineraryTopAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ItineraryTopAppBar({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: <Widget>[
        IconButton(
          onPressed: onClose ?? () {},
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }
}
