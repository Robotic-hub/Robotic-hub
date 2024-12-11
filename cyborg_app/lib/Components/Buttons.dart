import 'package:cyborg_app/Components/Texts.dart';
import 'package:flutter/material.dart';

class Buttons extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  const Buttons({
    super.key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).canvasColor,
      ),

      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Texts(text: text, size: 17),
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            backgroundColor: WidgetStatePropertyAll(backgroundColor),
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
            minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50)),
          ),
        ),
      ),
    );
  }
}
