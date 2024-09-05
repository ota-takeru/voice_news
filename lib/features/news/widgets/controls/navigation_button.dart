import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';

class NavigationButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle style;
  final IconData? icon;
  final double iconSize;
  final bool iconOnRight;
  final double fontSize;
  final String? semanticLabel;

  const NavigationButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.style,
    this.icon,
    this.iconSize = 40,
    this.iconOnRight = false,
    this.fontSize = 18,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: onPressed == null ? AppColors.disabled : null,
        ),
      ),
    ];

    if (icon != null) {
      final iconWidget = Icon(icon, size: iconSize);
      const boxWidget = SizedBox(width: 8);
      if (iconOnRight) {
        children.addAll([boxWidget, iconWidget]);
      } else {
        children.insertAll(0, [iconWidget, boxWidget]);
      }
    }

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      child: ElevatedButton(
        onPressed: onPressed,
        style: onPressed == null
            ? style.copyWith(
                backgroundColor: WidgetStateProperty.all(AppColors.background),
                foregroundColor: WidgetStateProperty.all(AppColors.disabled),
              )
            : style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class ButtonStyles {
  static ButtonStyle baseStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
    minimumSize: const Size(100, 60),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle nextButton({required bool isActive}) {
    return baseStyle.copyWith(
      backgroundColor: WidgetStateProperty.all(
          isActive ? AppColors.primary : AppColors.background),
      foregroundColor:
          WidgetStateProperty.all(isActive ? Colors.white : AppColors.disabled),
    );
  }

  static ButtonStyle prevButton({required bool isActive}) {
    return baseStyle.copyWith(
      backgroundColor: WidgetStateProperty.all(
          isActive ? AppColors.secondary : AppColors.background),
      foregroundColor:
          WidgetStateProperty.all(isActive ? Colors.white : AppColors.disabled),
      side: WidgetStateProperty.all(BorderSide(
          color: isActive ? AppColors.primary : AppColors.disabled, width: 2)),
      elevation: WidgetStateProperty.all(0),
    );
  }
}
