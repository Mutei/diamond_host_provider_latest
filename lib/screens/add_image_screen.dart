// File: add_image_screen.dart

import 'dart:io';

import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/utils/under_process_dialog.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:reorderables/reorderables.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/language_constants.dart';
import '../backend/adding_estate_services.dart';
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
  State<AddImage> createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  final storageRef = FirebaseStorage.instance.ref();
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];

  Future<void> _getFromGallery() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  /// Simple upload (unused, but kept for reference)
  Future<String?> _uploadFile(File file, int index) async {
    final ref = storageRef.child(widget.IDEstate).child('$index.jpg');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  /// Upload with progress reporting
  Future<String?> _uploadFileWithProgress(
    File file,
    int index,
    int totalImages,
    ValueNotifier<double> notifier,
  ) async {
    final ref = storageRef.child(widget.IDEstate).child('$index.jpg');
    final UploadTask task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes != 0) {
        final filePct = snapshot.bytesTransferred / snapshot.totalBytes!;
        notifier.value = (index + filePct) / totalImages;
      }
    });

    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  Future<void> _saveImages() async {
    if (_images.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text: 'Failure',
          text1: 'Please add at least one image before saving.',
        ),
      );
      return;
    }

    // 1. Prepare progress notifier and show dialog
    final totalImages = _images.length;
    final progressNotifier = ValueNotifier<double>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, percent, _) {
              final display = (percent * 100).clamp(0, 100).toStringAsFixed(0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${getTranslated(context, "DoNotCloseApp")}: $display%'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: percent),
                ],
              );
            },
          ),
        ),
      ),
    );

    // 2. Mark estate as completed
    final backendService = AddEstateServices();
    await backendService.markEstateAsCompleted(
      widget.typeEstate,
      widget.IDEstate,
    );

    // 3. Optional SMS notification
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userSnap =
          await FirebaseDatabase.instance.ref('App/User/$userId').get();
      if (userSnap.exists) {
        final phone = (userSnap.value as Map)['PhoneNumber'];
        await Dio().post(
          'https://backend-call-center-2.onrender.com/send-sms/underprocess',
          data: {
            'to': phone,
            'message':
                'شكرا لتعاملكم مع شركة diamondhost لتطبيق رضاك سيتم معالجة طلبك في اقرب وقت ممكن ',
            'sender': 'DiamondHost',
          },
        );
      }
    } catch (_) {}

    // 4. Upload images with progress
    final imageUrls = <String>[];
    for (var i = 0; i < _images.length; i++) {
      final url = await _uploadFileWithProgress(
        _images[i],
        i,
        totalImages,
        progressNotifier,
      );
      if (url != null) imageUrls.add(url);
    }

    // 5. Save URLs in Realtime Database
    final estateRef = FirebaseDatabase.instance
        .ref('App/Estate')
        .child(widget.typeEstate)
        .child(widget.IDEstate);
    await estateRef.child('ImageUrls').set(imageUrls);

    // 6. Close the progress dialog
    Navigator.of(context).pop();

    // 7. Show “under process” dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UnderProcessDialog(
        text: 'Processing',
        text1: 'Your request is under process.',
      ),
    );
    await Future.delayed(const Duration(seconds: 2));

    // 8. Navigate back to main
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _getFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: _images.isEmpty
                      ? Center(
                          child: Text(getTranslated(
                              context, "Please add at least one image")),
                        )
                      : ReorderableWrap(
                          spacing: 10,
                          runSpacing: 20,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              final img = _images.removeAt(oldIndex);
                              _images.insert(newIndex, img);
                            });
                          },
                          children: List.generate(_images.length, (index) {
                            final file = _images[index];
                            final double size =
                                (MediaQuery.of(context).size.width - 80) / 2;
                            return Stack(
                              key: ValueKey(file.path),
                              children: [
                                SizedBox(
                                  width: size,
                                  height: size,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      width: size,
                                      height: size,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _images.removeAt(index)),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurpleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveImages,
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
