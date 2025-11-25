import 'package:flutter/material.dart';

/// Creates a primary action button style with custom color
ButtonStyle createPrimaryButtonStyle({
  required Color backgroundColor,
  double minHeight = 56,
}) {
  return ElevatedButton.styleFrom(
    minimumSize: Size.fromHeight(minHeight),
    backgroundColor: backgroundColor,
  );
}

/// Creates a standard icon button for main actions
ElevatedButton createIconButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
  required Color backgroundColor,
  double iconSize = 24,
  double fontSize = 16,
  double minHeight = 56,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: iconSize),
    label: Text(
      label,
      style: TextStyle(fontSize: fontSize),
    ),
    style: createPrimaryButtonStyle(
      backgroundColor: backgroundColor,
      minHeight: minHeight,
    ),
  );
}

/// Standard spacing between major UI elements
const double standardSpacing = 16.0;

/// Standard padding for screens
const EdgeInsets standardScreenPadding = EdgeInsets.symmetric(
  horizontal: 24.0,
  vertical: 16.0,
);

/// Creates a labeled data card for displaying parsed ID information
Widget buildDataCard({
  required String label,
  required String value,
  Color? valueColor,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: valueColor,
        ),
      ),
    ),
  );
}

/// Creates a section header with consistent styling
Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

