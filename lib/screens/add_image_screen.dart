import 'dart:io';
import 'dart:typed_data';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/utils/under_process_dialog.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:reorderables/reorderables.dart';
import '../localization/language_constants.dart';
import 'package:image_picker/image_picker.dart';

import '../backend/adding_estate_services.dart';
import '../state_management/general_provider.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import 'main_screen.dart';

class AddImage extends StatefulWidget {
  final String IDEstate;
  final String typeEstate;

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

  final ImagePicker imgpicker = ImagePicker();
  List<File> image = [];

  Future<void> _getFromGallery() async {
    List<XFile>? pickedFile = await imgpicker.pickMultiImage();
    if (pickedFile != null) {
      setState(() {
        image.addAll(pickedFile.map((x) => File(x.path)));
      });
    }
  }

  Future<UploadTask?> uploadFile(File? file, String id) async {
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file was selected')),
      );
      return null;
    }
    Reference ref = storageRef.child(IDEstate).child('/$id.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': file.path},
    );
    return ref.putData(await file.readAsBytes(), metadata);
  }

  @override
  Widget build(BuildContext context) {
    final AddEstateServices backendService = AddEstateServices();

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
          ),
        ],
      ),
      body: Stack(
        children: [
          // scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 15, right: 15),
                  child: Text(
                    getTranslated(context, "Add Image"),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // white rounded container with reorderable images
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: image.isEmpty
                      ? Center(
                          child: Text(
                            getTranslated(
                                context, "Please add at least one image"),
                          ),
                        )
                      : ReorderableWrap(
                          spacing: 10,
                          runSpacing: 20,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              final img = image.removeAt(oldIndex);
                              image.insert(newIndex, img);
                            });
                          },
                          children: List.generate(image.length, (index) {
                            final file = image[index];
                            // compute a square size for two columns
                            final double size =
                                (MediaQuery.of(context).size.width - 80) / 2;
                            return Stack(
                              key: ValueKey(file.path),
                              children: [
                                // image box
                                Container(
                                  width: size,
                                  height: size,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => image.removeAt(index)),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                ),
              ],
            ),
          ),

          // save button
          Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: () async {
                if (image.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => const FailureDialog(
                      text: "Failure",
                      text1: "Please add at least one image before saving.",
                    ),
                  );
                  return;
                }
                showCustomLoadingDialog(context);
                await backendService.markEstateAsCompleted(
                    typeEstate, IDEstate);

                try {
                  final String userId = FirebaseAuth.instance.currentUser!.uid;
                  final userRef =
                      FirebaseDatabase.instance.ref().child('App/User/$userId');
                  final snapshot = await userRef.get();
                  if (snapshot.exists) {
                    final phoneNumber = (snapshot.value as Map)['PhoneNumber'];
                    await Dio().post(
                      'https://backend-call-center-2.onrender.com/send-sms/underprocess',
                      data: {
                        'to': phoneNumber,
                        'message':
                            'شكرا لتعاملكم مع شركة diamondhost لتطبيق رضاك سيتم معالجة طلبك في اقرب وقت ممكن ',
                        'sender': 'DiamondHost',
                      },
                    );
                  }
                } catch (e) {
                  debugPrint("SMS sending failed: $e");
                }

                // upload each file
                for (var i = 0; i < image.length; i++) {
                  await uploadFile(image[i], i.toString());
                }
                Navigator.of(context).pop(); // hide loading

                // show under process dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const UnderProcessDialog(
                    text: 'Processing',
                    text1: 'Your request is under process.',
                  ),
                );
                await Future.delayed(const Duration(seconds: 2));
                Navigator.of(context).pop(); // hide under process

                // go back to main screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              },
              child: Container(
                width: 150.w,
                height: 6.h,
                margin: const EdgeInsets.only(right: 40, left: 40, bottom: 20),
                decoration: BoxDecoration(
                  color: kPurpleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    getTranslated(context, "Save"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
