import 'package:cyborg_app/Pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 2, 23, 54),
        primaryColorDark: Colors.blue[900],
        primaryColorLight:Colors.green,
        primaryColor:const Color.fromARGB(255, 39, 39, 39),
        hintColor: Colors.red[300],
        canvasColor: Colors.white,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}
