// import 'dart:io';
// import 'package:daimond_host_provider/constants/colors.dart';
// import 'package:daimond_host_provider/constants/styles.dart';
// import 'package:daimond_host_provider/localization/language_constants.dart';
// import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../utils/failure_dialogue.dart';
// import '../utils/global_methods.dart';
// import '../utils/under_process_dialog.dart';
// import '../widgets/custom_button_2.dart';
//
// class AddPostScreen extends StatefulWidget {
//   final Map<dynamic, dynamic>? post;
//
//   const AddPostScreen({super.key, this.post});
//
//   @override
//   State<AddPostScreen> createState() => _AddPostScreenState();
// }
//
// class _AddPostScreenState extends State<AddPostScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _textController = TextEditingController();
//   String _postId = '';
//   List<File> _imageFiles = [];
//   List<File> _videoFiles = [];
//   final ImagePicker _picker = ImagePicker();
//   String? _selectedEstate;
//   List<Map<dynamic, dynamic>> _userEstates = [];
//   String userType = "2";
//   String? typeAccount;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Show loading dialog
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       showCustomLoadingDialog(context);
//     });
//
//     if (widget.post != null) {
//       _postId = widget.post!['postId'];
//       _titleController.text = widget.post!['Description'];
//       _textController.text = widget.post!['Text'];
//       _selectedEstate = widget.post!['EstateType'];
//     }
//     // Fetch data and close loading dialog when done
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     await _fetchUserEstates();
//     await _loadUserType();
//     await _loadTypeAccount();
//
//     // Close the loading dialog once all data is loaded
//     Navigator.of(context).pop(); // Dismiss the loading dialog
//   }
//
//   Future<void> _loadUserType() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       userType = prefs.getString("TypeUser") ?? "2";
//     });
//   }
//
//   Future<void> _loadTypeAccount() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       DatabaseReference typeAccountRef = FirebaseDatabase.instance
//           .ref("App")
//           .child("User")
//           .child(user.uid)
//           .child("TypeAccount");
//       DataSnapshot snapshot = await typeAccountRef.get();
//       if (snapshot.exists) {
//         setState(() {
//           typeAccount = snapshot.value.toString();
//         });
//       }
//     }
//   }
//
//   Future<void> _fetchUserEstates() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       return;
//     }
//     String userId = user.uid;
//
//     DatabaseReference estateRef =
//         FirebaseDatabase.instance.ref("App").child("Estate");
//     DatabaseEvent estateEvent = await estateRef.once();
//     Map<dynamic, dynamic>? estatesData =
//         estateEvent.snapshot.value as Map<dynamic, dynamic>?;
//
//     if (estatesData != null) {
//       List<Map<dynamic, dynamic>> userEstates = [];
//       estatesData.forEach((estateType, estates) {
//         if (estates is Map<dynamic, dynamic>) {
//           estates.forEach((key, value) {
//             // Check if the estate belongs to the user and if IsAccepted == "2"
//             if (value != null &&
//                 value['IDUser'] == userId &&
//                 value['IsAccepted'] == "2") {
//               userEstates.add({
//                 'type': estateType,
//                 'data': value,
//                 'id': key,
//                 'IDEstate': value['IDEstate'], // Include the IDEstate field
//               });
//             }
//           });
//         }
//       });
//
//       setState(() {
//         _userEstates = userEstates;
//         if (_userEstates.isNotEmpty &&
//             !_userEstates.any((estate) => estate['id'] == _selectedEstate)) {
//           _selectedEstate = _userEstates.first['id'];
//         }
//       });
//     }
//   }
//
//   Future<void> _pickImages() async {
//     final pickedFiles = await _picker.pickMultiImage();
//     if (pickedFiles != null) {
//       setState(() {
//         _imageFiles =
//             pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
//       });
//     }
//   }
//
//   Future<void> _pickVideos() async {
//     final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _videoFiles.add(File(pickedFile.path));
//       });
//     }
//   }
//
//   /// Saves the post to Firebase Realtime Database and uploads media to Firebase Storage
//   Future<void> _savePost() async {
//     if (_formKey.currentState!.validate() &&
//         (_selectedEstate != null || userType != "2")) {
//       if (await _canAddMorePosts()) {
//         setState(() {
//           _isLoading = true;
//         });
//
//         try {
//           User? user = FirebaseAuth.instance.currentUser;
//           if (user == null) {
//             await showDialog(
//               context: context,
//               builder: (context) => FailureDialog(
//                 text: "Error",
//                 text1: "User not authenticated",
//               ),
//             );
//             return;
//           }
//           String userId = user.uid;
//
//           String? profileImageUrl;
//           DataSnapshot userSnapshot = await FirebaseDatabase.instance
//               .ref("App")
//               .child("User")
//               .child(userId)
//               .get();
//           if (userSnapshot.exists) {
//             Map<dynamic, dynamic> userData =
//                 userSnapshot.value as Map<dynamic, dynamic>;
//             profileImageUrl = userData['ProfileImageUrl'];
//           }
//
//           Map<dynamic, dynamic> selectedEstate = _selectedEstate != null
//               ? _userEstates.firstWhere(
//                   (estate) => estate['id'] == _selectedEstate,
//                   orElse: () => {},
//                 )
//               : {};
//
//           if (_selectedEstate != null && selectedEstate.isEmpty) {
//             await showDialog(
//               context: context,
//               builder: (context) => FailureDialog(
//                 text: "Error",
//                 text1: "You don't have this estate",
//               ),
//             );
//             return;
//           }
//
//           DatabaseReference postsRef =
//               FirebaseDatabase.instance.ref("App").child("AllPosts");
//
//           if (_postId.isEmpty) {
//             _postId = postsRef.push().key!;
//           }
//
//           List<String> imageUrls = [];
//           for (File imageFile in _imageFiles) {
//             UploadTask uploadTask = FirebaseStorage.instance
//                 .ref()
//                 .child('post_images')
//                 .child('$_postId${imageFile.path.split('/').last}')
//                 .putFile(imageFile);
//             TaskSnapshot snapshot = await uploadTask;
//             String imageUrl = await snapshot.ref.getDownloadURL();
//             imageUrls.add(imageUrl);
//           }
//
//           List<String> videoUrls = [];
//           for (File videoFile in _videoFiles) {
//             UploadTask uploadTask = FirebaseStorage.instance
//                 .ref()
//                 .child('post_videos')
//                 .child('$_postId${videoFile.path.split('/').last}')
//                 .putFile(videoFile);
//             TaskSnapshot snapshot = await uploadTask;
//             String videoUrl = await snapshot.ref.getDownloadURL();
//             videoUrls.add(videoUrl);
//           }
//
//           String? estateName;
//           if (userType == "2") {
//             estateName = selectedEstate['data']['NameEn'];
//           } else {
//             if (userSnapshot.exists) {
//               Map<dynamic, dynamic> userData =
//                   userSnapshot.value as Map<dynamic, dynamic>;
//               estateName =
//                   '${userData['FirstName']} ${userData['SecondName']} ${userData['LastName']}';
//             } else {
//               estateName = 'Unknown User';
//             }
//           }
//
//           await postsRef.child(_postId).set({
//             'Description': _titleController.text,
//             'Date': DateTime.now().millisecondsSinceEpoch,
//             'Username': estateName,
//             'EstateType': selectedEstate['type'],
//             'EstateID': selectedEstate['data']
//                 ['IDEstate'], // Save EstateID here
//             'userId': userId,
//             'userType': userType,
//             'typeAccount': typeAccount,
//             'ImageUrls': imageUrls,
//             'VideoUrls': videoUrls,
//             'ProfileImageUrl': profileImageUrl,
//             'likes': {'count': 0, 'users': {}},
//             'comments': {'count': 0, 'list': {}},
//             'Status':
//                 "0", // New status field indicating the post is under process
//           });
//
//           await showDialog(
//             context: context,
//             builder: (context) => const UnderProcessDialog(
//               text: "Under Process",
//               text1: "Your post is under process for review",
//             ),
//           );
//           Navigator.pop(context); // Navigate back after dialog is closed
//         } catch (e) {
//           await showDialog(
//             context: context,
//             builder: (context) => FailureDialog(
//               text: "Error",
//               text1: "Failed to add post",
//             ),
//           );
//         } finally {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }
//
//   /// Checks if the user can add more posts based on their subscription and activity
//   Future<bool> _canAddMorePosts() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       showDialog(
//         context: context,
//         builder: (context) => FailureDialog(
//           text: "Error",
//           text1: "User not authenticated",
//         ),
//       );
//       return false;
//     }
//
//     // Disallow posts for users with TypeAccount "1"
//     if (typeAccount == "1") {
//       showDialog(
//         context: context,
//         builder: (context) => FailureDialog(
//           text: "Post not added",
//           text1:
//               "You should subscribe to premium or premium plus to add posts.",
//         ),
//       );
//       return false;
//     }
//
//     DatabaseReference postsRef =
//         FirebaseDatabase.instance.ref("App").child("AllPosts");
//
//     DatabaseEvent postsEvent =
//         await postsRef.orderByChild('userId').equalTo(user.uid).once();
//     Map<dynamic, dynamic>? postsData =
//         postsEvent.snapshot.value as Map<dynamic, dynamic>?;
//
//     if (postsData != null) {
//       int count = 0;
//       DateTime now = DateTime.now();
//       DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));
//
//       postsData.forEach((key, value) {
//         DateTime postDate = DateTime.fromMillisecondsSinceEpoch(value['Date']);
//         if (postDate.isAfter(thirtyDaysAgo)) {
//           count++;
//         }
//       });
//
//       int allowedPosts = 0;
//       if (userType == '1' && typeAccount == '2') {
//         allowedPosts = 4;
//       } else if (userType == '1' && typeAccount == '3') {
//         allowedPosts = 10;
//       } else if (userType == '2' && typeAccount == '2') {
//         allowedPosts = 4;
//       } else if (userType == '2' && typeAccount == '3') {
//         allowedPosts = 8;
//       } else {
//         _showPostLimitAlert(allowedPosts, typeAccount!);
//         return false;
//       }
//
//       if (count >= allowedPosts) {
//         _showPostLimitAlert(allowedPosts, typeAccount!);
//         return false;
//       }
//     }
//     return true;
//   }
//
//   /// Shows an alert when the user has reached the post limit
//   /// Shows an alert when the user has reached the post limit
//   void _showPostLimitAlert(int allowedPosts, String typeAccount) {
//     showDialog(
//       context: context,
//       builder: (context) => FailureDialog(
//           text: "Post Limit Reached",
//           text1: typeAccount == "2"
//               ? "You have added 4 Posts in a month. You can't add more!"
//               : "You have added 8 Posts in a month. You can't add more!"),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         iconTheme: kIconTheme,
//         centerTitle: true,
//         title: Text(
//           widget.post == null ? getTranslated(context, "Post") : "Edit Post",
//           style: TextStyle(
//             color: kDeepPurpleColor,
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (userType == "2")
//                       DropdownButtonFormField<String>(
//                         value: _selectedEstate,
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor:
//                               Theme.of(context).brightness == Brightness.dark
//                                   ? kDarkModeColor
//                                   : Colors.grey[200],
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                         ),
//                         hint: Text(getTranslated(context, "Select Estate")),
//                         items: _userEstates.map((estate) {
//                           return DropdownMenuItem<String>(
//                             value: estate['id'],
//                             child: Text(
//                                 '${estate['data']['NameEn']} (${estate['type']})'),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedEstate = value;
//                           });
//                         },
//                         validator: (value) {
//                           if (value == null && userType == "2") {
//                             return 'Please select an estate';
//                           }
//                           return null;
//                         },
//                       ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _titleController,
//                       maxLength: 120,
//                       maxLines: null,
//                       decoration: InputDecoration(
//                         labelText: getTranslated(context, "Title"),
//                         filled: true,
//                         fillColor:
//                             Theme.of(context).brightness == Brightness.dark
//                                 ? kDarkModeColor
//                                 : Colors.grey[200],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return getTranslated(context, 'Please enter a title');
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     if (_imageFiles.isEmpty && _videoFiles.isEmpty)
//                       Container(
//                         alignment: Alignment.center,
//                         height: 150,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8.0),
//                           color: Theme.of(context).brightness == Brightness.dark
//                               ? Colors.black
//                               : Colors.grey[200],
//                         ),
//                         child: Text(
//                           getTranslated(context, "No media selected."),
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       )
//                     else
//                       SizedBox(
//                         height: 150,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: _imageFiles.length + _videoFiles.length,
//                           itemBuilder: (context, index) {
//                             if (index < _imageFiles.length) {
//                               return Padding(
//                                 padding: const EdgeInsets.all(4.0),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(8.0),
//                                   child: Image.file(_imageFiles[index]),
//                                 ),
//                               );
//                             } else {
//                               return Padding(
//                                 padding: const EdgeInsets.all(4.0),
//                                 child: Container(
//                                   width: 150,
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8.0),
//                                     color: Colors.grey[800],
//                                   ),
//                                   child: Center(
//                                     child: Icon(
//                                       Icons.videocam,
//                                       color: Colors.white,
//                                       size: 60,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ReusableIconButton(
//                             onPressed: _pickImages,
//                             icon:
//                                 Icon(Icons.photo_library, color: Colors.white),
//                             label: getTranslated(context, "Pick Images"),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         if (userType == "2" &&
//                             (typeAccount == "2" || typeAccount == "3"))
//                           Expanded(
//                             child: ReusableIconButton(
//                               onPressed: _pickVideos,
//                               icon: Icon(Icons.video_library,
//                                   color: Colors.white),
//                               label: getTranslated(context, "Pick Videos"),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: CustomButton(
//                         text: getTranslated(context, "Save"),
//                         onPressed: _savePost,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black54,
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/under_process_dialog.dart';
import '../widgets/custom_button_2.dart';
import '../widgets/reused_elevated_button.dart';

class AddPostScreen extends StatefulWidget {
  final Map<dynamic, dynamic>? post;

  const AddPostScreen({super.key, this.post});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  String _postId = '';

  List<File> _imageFiles = [];
  List<File> _videoFiles = [];
  List<String> _existingImageUrls = [];
  List<String> _existingVideoUrls = [];

  final ImagePicker _picker = ImagePicker();

  String? _selectedEstate;
  List<Map<dynamic, dynamic>> _userEstates = [];
  String userType = "2";
  String? typeAccount;

  bool _isLoading = false;
  double _uploadProgress = 0.0;

  /*──────────────────────────── INIT ─────────────────────────────*/
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCustomLoadingDialog(context);
    });

    if (widget.post != null) {
      _postId = widget.post!["postId"]?.toString() ?? '';
      _titleController.text = (widget.post!["Description"] ?? '').toString();
      _textController.text = (widget.post!["Text"] ?? '').toString();
      _selectedEstate = widget.post!["EstateID"]?.toString() ??
          widget.post!["EstateType"]?.toString();
      _existingImageUrls = List<String>.from(widget.post!["ImageUrls"] ?? []);
      _existingVideoUrls = List<String>.from(widget.post!["VideoUrls"] ?? []);
    }

    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchUserEstates(),
      _loadUserType(),
      _loadTypeAccount(),
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  /*──────────────────────────── BASIC FETCH ──────────────────────────*/
  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userType = prefs.getString("TypeUser") ?? "2");
  }

  Future<void> _loadTypeAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseDatabase.instance
        .ref('App/User/${user.uid}/TypeAccount')
        .get();
    if (snap.exists) setState(() => typeAccount = snap.value.toString());
  }

  Future<void> _fetchUserEstates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseDatabase.instance.ref('App/Estate').once();
    final data = snap.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    final estates = <Map<dynamic, dynamic>>[];
    data.forEach((estateType, estatesMap) {
      if (estatesMap is Map) {
        estatesMap.forEach((key, value) {
          if (value != null &&
              value['IDUser'] == user.uid &&
              value['IsAccepted'] == "2") {
            estates.add({
              'type': estateType,
              'data': value,
              'id': key,
              'IDEstate': value['IDEstate'],
            });
          }
        });
      }
    });

    setState(() {
      _userEstates = estates;
      if (widget.post == null && userType == '2' && estates.isNotEmpty) {
        _selectedEstate = estates.first['id'];
      }
    });
  }

  /*──────────────────────────── MEDIA PICKERS ──────────────────────────*/
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() => _imageFiles = picked.map((e) => File(e.path)).toList());
    }
  }

  Future<void> _pickVideos() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFiles.add(File(picked.path)));
  }

  /*──────────────────────────── POST LIMIT ─────────────────────────────*/
  void _showPostLimitAlert(int allowed, String typeAccount) {
    late String msg;
    switch (typeAccount) {
      case '1':
        msg = 'You have added 1 Post in a month. You cannot add more!';
        break;
      case '2':
        msg = 'You have added 4 Posts in a month. You cannot add more!';
        break;
      case '3':
        msg = 'You have added 8 Posts in a month. You cannot add more!';
        break;
      default:
        msg = 'Post Limit Reached';
    }
    showDialog(
      context: context,
      builder: (_) => FailureDialog(text: 'Post Limit Reached', text1: msg),
    );
  }

  Future<bool> _canAddMorePosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await FirebaseDatabase.instance
        .ref('App/AllPosts')
        .orderByChild('userId')
        .equalTo(user.uid)
        .once();
    final data = snap.snapshot.value as Map<dynamic, dynamic>?;

    int monthlyCount = 0;
    if (data != null) {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      data.forEach((_, value) {
        if (value is Map) {
          final ts = value['Date'] as int?;
          if (ts != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(ts);
            if (date.isAfter(cutoff)) monthlyCount++;
          }
        }
      });
    }

    int allowed = 0;
    if (userType == '1' && typeAccount == '2') allowed = 4;
    if (userType == '1' && typeAccount == '3') allowed = 10;
    if (userType == '2' && typeAccount == '1') allowed = 1;
    if (userType == '2' && typeAccount == '2') allowed = 4;
    if (userType == '2' && typeAccount == '3') allowed = 8;

    if (allowed > 0 && monthlyCount >= allowed) {
      _showPostLimitAlert(allowed, typeAccount ?? '');
      return false;
    }
    return true;
  }

  /*──────────────────────────── SAVE POST ─────────────────────────────*/
  Future<File> _compressVideo(File file) async {
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    if (info != null && info.path != null) return File(info.path!);
    return file;
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;
    if (userType == '2' && _selectedEstate == null) {
      showDialog(
        context: context,
        builder: (_) =>
            FailureDialog(text: 'Error', text1: 'Please select an estate.'),
      );
      return;
    }
    if (!await _canAddMorePosts()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final postsRef = FirebaseDatabase.instance.ref('App/AllPosts');
      if (_postId.isEmpty) _postId = postsRef.push().key!;

      final imageUrls = <String>[];
      for (final img in _imageFiles) {
        final task = FirebaseStorage.instance
            .ref('post_images/$_postId${img.path.split('/').last}')
            .putFile(img);
        task.snapshotEvents.listen((e) => setState(
            () => _uploadProgress = e.bytesTransferred / e.totalBytes));
        imageUrls.add(await (await task).ref.getDownloadURL());
      }

      final videoUrls = <String>[];
      for (final vid in _videoFiles) {
        final compressed = await _compressVideo(vid);
        final task = FirebaseStorage.instance
            .ref('post_videos/$_postId${vid.path.split('/').last}')
            .putFile(compressed);
        task.snapshotEvents.listen((e) => setState(
            () => _uploadProgress = e.bytesTransferred / e.totalBytes));
        videoUrls.add(await (await task).ref.getDownloadURL());
      }

      final allImageUrls = [..._existingImageUrls, ...imageUrls];
      final allVideoUrls = [..._existingVideoUrls, ...videoUrls];

      String? profileImageUrl;
      final userSnap =
          await FirebaseDatabase.instance.ref('App/User/${user.uid}').get();
      if (userSnap.exists) {
        final m = userSnap.value as Map<dynamic, dynamic>;
        profileImageUrl = m['ProfileImageUrl'] as String?;
      }

      Map<dynamic, dynamic>? selectedEstateData;
      if (userType == '2') {
        selectedEstateData = _userEstates.firstWhere(
          (e) => e['id'] == _selectedEstate,
          orElse: () => {},
        );
      }

      String estateName;
      String? estateType;
      String? estateId;
      if (userType == '2') {
        estateName = selectedEstateData!["data"]["NameEn"] ?? 'Unknown Estate';
        estateType = selectedEstateData['type']?.toString();
        estateId = selectedEstateData['data']['IDEstate']?.toString();
      } else {
        estateName = [
          userSnap.child('FirstName').value,
          userSnap.child('SecondName').value,
          userSnap.child('LastName').value,
        ].whereType<String>().join(' ');
      }

      await postsRef.child(_postId).set({
        'Description': _titleController.text.trim(),
        'Text': _textController.text.trim(),
        'Date': DateTime.now().millisecondsSinceEpoch,
        'Username': estateName,
        'EstateType': estateType,
        'EstateID': estateId,
        'userId': user.uid,
        'userType': userType,
        'typeAccount': typeAccount,
        'ImageUrls': allImageUrls,
        'VideoUrls': allVideoUrls,
        'ProfileImageUrl': profileImageUrl,
        'likes': {'count': 0, 'users': {}},
        'comments': {'count': 0, 'list': {}},
        'Status': widget.post == null ? '0' : (widget.post!['Status'] ?? '0'),
      });

      await showDialog(
        context: context,
        builder: (_) => const UnderProcessDialog(
          text: 'Under Process',
          text1: 'Your post is under process for review',
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) =>
            FailureDialog(text: 'Error', text1: 'Failed to add post'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /*──────────────────────────── UI ─────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          widget.post == null ? getTranslated(context, 'Post') : 'Edit Post',
          style: TextStyle(color: kDeepPurpleColor),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userType == '2') _buildEstateDropdown(isDark),
                    const SizedBox(height: 16),
                    _buildTitleField(isDark),
                    const SizedBox(height: 16),
                    _buildMediaPreview(isDark),
                    const SizedBox(height: 16),
                    _buildPickButtons(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: getTranslated(context, 'Save'),
                        onPressed: _savePost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  /*──────────────────────────── UI Helpers ─────────────────────*/
  Widget _buildEstateDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedEstate,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? kDarkModeColor : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: Text(getTranslated(context, 'Select Estate')),
      items: _userEstates.map((e) {
        return DropdownMenuItem<String>(
          value: e['id'],
          child: Text('${e['data']['NameEn']} (${e['type']})',
              overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedEstate = v),
      validator: (v) {
        if (userType == '2' && v == null) return 'Please select an estate';
        return null;
      },
    );
  }

  Widget _buildTitleField(bool isDark) => TextFormField(
        controller: _titleController,
        maxLength: 120,
        decoration: InputDecoration(
          labelText: getTranslated(context, 'Title'),
          filled: true,
          fillColor: isDark ? kDarkModeColor : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) => v == null || v.isEmpty
            ? getTranslated(context, 'Please enter a title')
            : null,
      );

  Widget _buildPickButtons() => Row(
        children: [
          Expanded(
            child: ReusableIconButton(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: getTranslated(context, 'Pick Images'),
            ),
          ),
          const SizedBox(width: 16),
          if (userType == '2')
            Expanded(
              child: ReusableIconButton(
                onPressed: _pickVideos,
                icon: const Icon(Icons.video_library, color: Colors.white),
                label: getTranslated(context, 'Pick Videos'),
              ),
            ),
        ],
      );

  /*──────────────────────────── Media Preview ─────────────────────*/
  Widget _removableThumb(
          {required Widget child, required VoidCallback onRemove}) =>
      Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            )
          ],
        ),
      );

  Widget _buildMediaPreview(bool isDark) {
    final widgets = <Widget>[];

    for (final url in _existingImageUrls) {
      widgets.add(_removableThumb(
          child: Image.network(url, fit: BoxFit.cover, width: 150),
          onRemove: () => setState(() => _existingImageUrls.remove(url))));
    }

    for (final file in _imageFiles) {
      widgets.add(_removableThumb(
          child: Image.file(file, fit: BoxFit.cover, width: 150),
          onRemove: () => setState(() => _imageFiles.remove(file))));
    }

    for (final url in _existingVideoUrls) {
      widgets.add(_removableThumb(
          child: Container(
            width: 150,
            color: Colors.grey[800],
            child:
                const Center(child: Icon(Icons.videocam, color: Colors.white)),
          ),
          onRemove: () => setState(() => _existingVideoUrls.remove(url))));
    }

    for (final file in _videoFiles) {
      widgets.add(_removableThumb(
          child: Container(
            width: 150,
            color: Colors.grey[800],
            child:
                const Center(child: Icon(Icons.videocam, color: Colors.white)),
          ),
          onRemove: () => setState(() => _videoFiles.remove(file))));
    }

    if (widgets.isEmpty) {
      return Container(
        alignment: Alignment.center,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? Colors.black : Colors.grey[200],
        ),
        child: Text(getTranslated(context, 'No media selected.'),
            style: TextStyle(color: Colors.grey[600])),
      );
    }

    return SizedBox(
        height: 150,
        child: ListView(scrollDirection: Axis.horizontal, children: widgets));
  }

  Widget _buildUploadingOverlay() => Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                color: kPrimaryColor,
                strokeWidth: 6,
              ),
              const SizedBox(height: 20),
              Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              Text(getTranslated(context, 'Uploading your media...'),
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    VideoCompress.cancelCompression();
    super.dispose();
  }
}
