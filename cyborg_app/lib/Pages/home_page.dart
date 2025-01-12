import 'dart:convert';
import 'dart:io';

import 'package:cyborg_app/Components/Buttons.dart';
import 'package:cyborg_app/Components/Texts.dart';
import 'package:cyborg_app/Pages/FaceVerificationPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  String? imageUrl;
  String? selectedAddress;
  List<dynamic>? addresses;
  late Future<List<dynamic>> _futureAddresses;

  @override
  void initState() {
    super.initState();
    _futureAddresses = getAddressAndStamp();
  }

  Future<List<dynamic>> getAddressAndStamp() async {
    final url = Uri.parse('http://192.168.0.242:8000/get_stamp/');
    try {
      var res = await http.get(url);
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body)['data']!;
        setState(() {
          addresses = jsonData;
        });
        return jsonData;
      } else {
        throw Exception('Failed to fetch data. Status Code: ${res.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 10,
        title: const Text('CYBORG CERTIFIER'),
        foregroundColor: Theme.of(context).canvasColor,
        backgroundColor: Theme.of(context).primaryColorDark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Card(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 10,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Center(
                        child: Texts(
                          text:
                              'Hi, Please enter your email below and choose the address next to your certifying facility.',
                          size: 16,
                          color: Theme.of(context).canvasColor,
                          bold: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Card(
                  elevation: 10,
                  child: TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<dynamic>>(
                  future: _futureAddresses,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snap.hasError) {
                      return const Center(
                        child: Text('Unexpected error occurred.'),
                      );
                    } else if (!snap.hasData || snap.data!.isEmpty) {
                      return const Center(child: Text('No data available!'));
                    } else {
                      var data = snap.data!;
                      return Column(
                        children: [
                          Card(
                            elevation: 10,
                            child: ExpansionTile(
                              collapsedBackgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              leading: Icon(
                                Icons.location_on_outlined,
                                color: Theme.of(context).canvasColor,
                              ),
                              showTrailingIcon: true,
                              title: Texts(
                                text: 'Select an address',
                                bold: FontWeight.bold,
                                color: Theme.of(context).canvasColor,
                                size: 17,
                              ),
                              children:
                                  data.map<Widget>((item) {
                                    return ListTile(
                                      title: Texts(
                                        text:
                                            item['address'] ??
                                            'No Available Data',
                                        bold: FontWeight.bold,
                                        color: Theme.of(context).canvasColor,
                                        size: 17,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedAddress = item['address'];
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                         
                          const SizedBox(height: 5),
                          Buttons(
                            text: 'Continue',
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                if ( 
                                    emailController.text.isNotEmpty &&
                                    selectedAddress != null) {
                                  final selectedStamp =
                                      data.firstWhere(
                                        (item) =>
                                            item['address'] == selectedAddress,
                                      )['stamp'] ??
                                      '';

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => FaceVerificationScreen(
                                            email: emailController.text,
                                            address: selectedAddress!,  
                                            stamp: selectedStamp, 
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill all fields and upload an image',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            foregroundColor: Theme.of(context).canvasColor,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
