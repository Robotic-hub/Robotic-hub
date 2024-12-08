import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:AppBar(
            title:Text('Upload Your ID'),
            foregroundColor: Theme.of(context).primaryColorLight,
            backgroundColor: Theme.of(context).primaryColorDark,
            centerTitle: true,
        ),
        body:Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 30,),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).primaryColorLight
                ),
                child: Text('Hi, Please enter your email on the following,and choose the address next to your certifying facility.'),
              ),
              Card(
                elevation: 10,
          
                child: TextField(
                  
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      
                    )
                  ),
                  
                ),)
          
          ],),
        )
    );
  }
}