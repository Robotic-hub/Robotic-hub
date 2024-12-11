import 'package:cyborg_app/Components/Buttons.dart';
import 'package:cyborg_app/Components/Texts.dart';
import 'package:cyborg_app/Pages/FaceVerificationPage.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  TextEditingController emailController = TextEditingController();
  String? imageUrl;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 10,
        title: Text('CYBORG CERTIFIER'),

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
                SizedBox(height: 30),
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
                              'Hi, Please enter your email below and choose the address next to your certifyng facility.',
                          size: 16,
                          color: Theme.of(context).canvasColor,
                          bold: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Card(
                  elevation: 10,
                  child: TextField(
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).primaryColorDark,
                      focusColor: Theme.of(context).primaryColorDark,
                      hintText: 'Enter your email',

                      labelStyle: TextStyle(color: Colors.white),
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
                  ),
                ),
                Card(
                  elevation: 10,
                  child: ExpansionTile(
                    collapsedBackgroundColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    children: [
                      ListTile(
                        title: Texts(
                          text: 'Ga Mathipa',
                          bold: FontWeight.bold,
                          color: Theme.of(context).canvasColor,
                          size: 17,
                        ),
                      ),
                      Divider(),
                      ListTile(
                        title: Texts(
                          text: 'Evaton west',
                          bold: FontWeight.bold,
                          color: Theme.of(context).canvasColor,
                          size: 17,
                        ),
                      ),
                      Divider(),

                      ListTile(
                        title: Texts(
                          text: 'Ga Mphethi',
                          bold: FontWeight.bold,
                          color: Theme.of(context).canvasColor,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                FormBuilderFilePicker(
                  name: "attachments",
                  allowMultiple: false,
                  withData: true,
                  typeSelectors: [
                    TypeSelector(
                      type: FileType.image,
                      selector: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Theme.of(context).canvasColor,
                        elevation: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 20,
                                    color: Theme.of(context).canvasColor,
                                  ),
                                  Texts(
                                    text: 'Upload your ID as Image',
                                    bold: FontWeight.bold,
                                    color: Theme.of(context).canvasColor,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Buttons(
                  text: 'Continue',
                  onPressed: () {
                    final formState = _formKey.currentState;
                    if (formState != null && formState.saveAndValidate()) {
                      final file =
                          formState.fields['attachments']?.value
                              as List<PlatformFile>?;
                      if (file != null &&
                          file.isNotEmpty &&
                          emailController.text.isNotEmpty) {
                        setState(() {
                          imageUrl =
                              file
                                  .first
                                  .path;  
                        });
                      }
                    } 
                    print('Here is your url path for the image: $imageUrl');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FaceVerificationScreen(
                              email: emailController.text,
                              address: 'Ga Mathipa',
                              imageUrl: imageUrl,
                            ),
                      ),
                    );
                  },
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  foregroundColor: Theme.of(context).canvasColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
