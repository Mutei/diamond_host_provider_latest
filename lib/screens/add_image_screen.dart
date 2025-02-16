import 'dart:io';
import 'dart:typed_data';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/utils/under_process_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../localization/language_constants.dart';
import 'package:image_picker/image_picker.dart';

import '../backend/adding_estate_services.dart'; // Import the service
import '../state_management/general_provider.dart';
import 'main_screen.dart';
import 'main_screen_content.dart';

class AddImage extends StatefulWidget {
  final String IDEstate;
  final String typeEstate; // Made non-nullable and required

  const AddImage({
    super.key,
    required this.IDEstate,
    required this.typeEstate,
  });

  @override
  _State createState() => _State(IDEstate, typeEstate);
}

class _State extends State<AddImage> {
  final storageRef = FirebaseStorage.instance.ref();
  final GlobalKey<ScaffoldState> _scaffoldKey1 = GlobalKey<ScaffoldState>();
  final String IDEstate;
  final String typeEstate;

  _State(this.IDEstate, this.typeEstate);

  List<UploadTask> _uploadTasks = [];

  /// The user selects a file, and the task is added to the list.
  Future<UploadTask?> uploadFile(File? file, String id) async {
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file was selected'),
        ),
      );
      return null;
    } else {
      UploadTask uploadTask;

      // Create a Reference to the file
      Reference ref =
          FirebaseStorage.instance.ref().child(IDEstate).child('/${id}.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path},
      );

      uploadTask = ref.putData(await file.readAsBytes(), metadata);

      // Show the UnderProcessDialog instead of the SnackBar
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return UnderProcessDialog(
            text: 'Processing',
            text1: 'Your request is under process.',
          );
        },
      );

      return Future.value(uploadTask);
    }
  }

  final ImagePicker imgpicker = ImagePicker();
  List<File> image = [];
  late File imageFile;

  Future<void> _getFromGallery() async {
    List<XFile>? pickedFile = await imgpicker.pickMultiImage();
    if (pickedFile != null) {
      for (int i = 0; i < pickedFile.length; i++) {
        setState(() {
          imageFile = File(pickedFile[i].path);
          image.add(imageFile);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final objProvider = Provider.of<GeneralProvider>(context, listen: false);
    final AddEstateServices backendService =
        AddEstateServices(); // Instantiate the service

    return Scaffold(
      key: _scaffoldKey1,
      appBar: AppBar(
        iconTheme: kIconTheme,
        actions: [
          Container(
            margin: const EdgeInsets.all(5),
            child: InkWell(
              child: const Icon(Icons.add),
              onTap: _getFromGallery,
            ),
          )
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 30, left: 15, right: 15),
              child: ListView(
                children: [
                  Container(
                    height: 100,
                    margin: const EdgeInsets.only(top: 30, left: 15, right: 15),
                    child: Text(
                      getTranslated(context, "Add Image"),
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(40.0),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: image.length,
                        itemBuilder: (BuildContext ctx, index) {
                          return Container(
                            margin: const EdgeInsets.all(20),
                            child: Image.file(
                              image[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                child: Container(
                  width: 150.w,
                  height: 6.h,
                  margin:
                      const EdgeInsets.only(right: 40, left: 40, bottom: 20),
                  decoration: BoxDecoration(
                    color: kPurpleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      getTranslated(context, "Save"),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onTap: () async {
                  // Mark the estate as completed first
                  await backendService.markEstateAsCompleted(
                      typeEstate, IDEstate);

                  // Upload all selected images
                  for (int i = 0; i < image.length; i++) {
                    UploadTask? task = await uploadFile(image[i], i.toString());
                    // Optionally, handle task completion or errors
                  }

                  // Navigate to MainScreen after completion
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainScreenContent(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
