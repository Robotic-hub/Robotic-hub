import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Texts extends StatelessWidget {
  final String text;
  final FontWeight? bold;
  final Color? color;
  final double? size;
  const Texts({super.key, required this.text,   this.bold,   this.color,   this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: size,
        color: color,
        fontWeight: bold,
      ),
    );
  }
}
