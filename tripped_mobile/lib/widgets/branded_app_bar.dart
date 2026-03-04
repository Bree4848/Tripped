import 'package:flutter/material.dart';

class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenName;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom; // Required for TabBars
  final Widget? leading; // ADDED: To support the back button

  const BrandedAppBar({
    super.key,
    required this.screenName,
    this.actions,
    this.backgroundColor,
    this.bottom,
    this.leading, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Default to Indigo if no color is provided
      backgroundColor: backgroundColor ?? Colors.indigo[900],
      foregroundColor: Colors.white,
      elevation: 2,

      // ADDED: This will display the back button when you pass it in
      leading: leading,

      // CenterTitle false keeps the logo/text to the left for a professional look
      centerTitle: false,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // THE LOGO: A yellow circle with a black bolt
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),

          // THE BRANDING TEXT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "TRIPPED",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                  fontFamily: 'Roboto', // Or your custom font
                ),
              ),
              Text(
                screenName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),

      // Pulls in the menu/actions (like search or logout)
      actions: actions,

      // This allows the TabBar to sit under the App Name in the Admin Dashboard
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    // If there is a TabBar, we need to double the height of the AppBar
    if (bottom != null) {
      return Size.fromHeight(kToolbarHeight + bottom!.preferredSize.height);
    }
    return const Size.fromHeight(kToolbarHeight);
  }
}
