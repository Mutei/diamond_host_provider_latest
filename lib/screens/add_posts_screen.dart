import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderables/reorderables.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/success_dialogue.dart';
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
  static const String _superUserId = 'NUiwMiP03lWcPZSYAUidWnNRkRz2';
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

  Future<void> _savePost() async {
    // 1️⃣ Super-user restriction
    if (typeAccount == "1" && _superUserId != 'NUiwMiP03lWcPZSYAUidWnNRkRz2') {
      showDialog(
        context: context,
        builder: (_) => FailureDialog(
          text: "Restricted",
          text1: "Your account type does not allow adding posts.",
        ),
      );
      return;
    }

    // 2️⃣ Form validation + estate selection
    if (!_formKey.currentState!.validate() ||
        (_selectedEstate == null && userType != "1")) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (_) => FailureDialog(
          text: "Error",
          text1: "User not authenticated",
        ),
      );
      return;
    }
    final userId = user.uid;
    final isSuperUser = userId == _superUserId;

    // 3️⃣ Post-limit check for non-super-users
    if (!isSuperUser && !await _canAddMorePosts()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 4️⃣ Fetch user profile image URL
      String? profileImageUrl;
      final userSnap =
          await FirebaseDatabase.instance.ref("App/User/$userId").get();
      if (userSnap.exists) {
        final userData = userSnap.value as Map<dynamic, dynamic>;
        profileImageUrl = userData['ProfileImageUrl'] as String?;
      }

      // 5️⃣ Find selected estate data (if provider)
      Map<dynamic, dynamic>? selectedEstateData;
      if (_selectedEstate != null) {
        selectedEstateData = _userEstates.firstWhere(
          (e) => e['id'] == _selectedEstate,
          orElse: () => {},
        );
        if (selectedEstateData.isEmpty) {
          showDialog(
            context: context,
            builder: (_) => FailureDialog(
              text: "Error",
              text1: "You don't have this estate",
            ),
          );
          return;
        }
      }

      // 6️⃣ Prepare database reference & new post ID
      final postsRef = FirebaseDatabase.instance.ref("App/AllPosts");
      if (_postId.isEmpty) {
        _postId = postsRef.push().key!;
      }

      // 7️⃣ Compute total bytes of all files
      int totalBytes = 0;
      for (final f in [..._imageFiles, ..._videoFiles]) {
        totalBytes += await f.length();
      }
      int cumulativeTransferred = 0;

      // 8️⃣ Upload images with aggregated progress
      final List<String> imageUrls = [];
      for (final img in _imageFiles) {
        final fileBytes = await img.length();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('$_postId${img.path.split('/').last}');
        final uploadTask = storageRef.putFile(img);

        final subscription = uploadTask.snapshotEvents.listen((snap) {
          final current = snap.bytesTransferred;
          setState(() {
            _uploadProgress = (cumulativeTransferred + current) / totalBytes;
          });
        });

        await uploadTask;
        await subscription.cancel();

        cumulativeTransferred += fileBytes;
        imageUrls.add(await storageRef.getDownloadURL());
      }

      // 9️⃣ Upload videos with aggregated progress
      final List<String> videoUrls = [];
      for (final vid in _videoFiles) {
        final fileBytes = await vid.length();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_videos')
            .child('$_postId${vid.path.split('/').last}');
        final uploadTask = storageRef.putFile(vid);

        final subscription = uploadTask.snapshotEvents.listen((snap) {
          final current = snap.bytesTransferred;
          setState(() {
            _uploadProgress = (cumulativeTransferred + current) / totalBytes;
          });
        });

        await uploadTask;
        await subscription.cancel();

        cumulativeTransferred += fileBytes;
        videoUrls.add(await storageRef.getDownloadURL());
      }

      // 🔟 Determine display name
      String estateName;
      if (userType == "2" &&
          selectedEstateData != null &&
          selectedEstateData.isNotEmpty) {
        estateName = selectedEstateData['data']['NameEn'] as String;
      } else if (userSnap.exists) {
        final u = userSnap.value as Map<dynamic, dynamic>;
        estateName = [u['FirstName'], u['SecondName'], u['LastName']]
            .whereType<String>()
            .join(' ');
      } else {
        estateName = 'Unknown User';
      }

      // ⓫ Write post to Realtime Database
      await postsRef.child(_postId).set({
        'Description': _titleController.text.trim(),
        'Text': _textController.text.trim(),
        'Date': DateTime.now().millisecondsSinceEpoch,
        'Username': estateName,
        'EstateType': selectedEstateData?['type'],
        'EstateID': selectedEstateData?['data']?['IDEstate'],
        'userId': userId,
        'userType': userType,
        'typeAccount': typeAccount,
        'ImageUrls': imageUrls,
        'VideoUrls': videoUrls,
        'ProfileImageUrl': profileImageUrl,
        'likes': {'count': 0, 'users': {}},
        'comments': {'count': 0, 'list': {}},
        'Status': isSuperUser ? '1' : '0',
      });

      // Show appropriate dialog
      await showDialog(
        context: context,
        builder: (_) => isSuperUser
            ? const SuccessDialog(
                text: "Success",
                text1: "Your post has been approved and is now visible.",
              )
            : const UnderProcessDialog(
                text: "Under Process",
                text1: "Your post is under process for review",
              ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text: "Error",
          text1: "Failed to add post",
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // Future<void> _savePost() async {
  //   if (typeAccount == "1" && _superUserId != 'NUiwMiP03lWcPZSYAUidWnNRkRz2') {
  //     showDialog(
  //       context: context,
  //       builder: (_) => FailureDialog(
  //         text: "Restricted",
  //         text1: "Your account type does not allow adding posts.",
  //       ),
  //     );
  //     return;
  //   }
  //   if (!_formKey.currentState!.validate() ||
  //       (_selectedEstate == null && userType != "1")) {
  //     return;
  //   }
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     showDialog(
  //       context: context,
  //       builder: (_) => FailureDialog(
  //         text: "Error",
  //         text1: "User not authenticated",
  //       ),
  //     );
  //     return;
  //   }
  //   final userId = user.uid;
  //   final isSuperUser = userId == _superUserId;
  //   if (!isSuperUser && !await _canAddMorePosts()) {
  //     return;
  //   }
  //   setState(() => _isLoading = true);
  //   try {
  //     String? profileImageUrl;
  //     final userSnap = await FirebaseDatabase.instance
  //         .ref("App")
  //         .child("User")
  //         .child(userId)
  //         .get();
  //     if (userSnap.exists) {
  //       final userData = userSnap.value as Map<dynamic, dynamic>;
  //       profileImageUrl = userData['ProfileImageUrl'];
  //     }
  //     final selectedEstate = _selectedEstate != null
  //         ? _userEstates.firstWhere(
  //           (e) => e['id'] == _selectedEstate,
  //       orElse: () => {},
  //     )
  //         : {};
  //     if (_selectedEstate != null && selectedEstate.isEmpty) {
  //       showDialog(
  //         context: context,
  //         builder: (_) => FailureDialog(
  //           text: "Error",
  //           text1: "You don't have this estate",
  //         ),
  //       );
  //       return;
  //     }
  //     final postsRef = FirebaseDatabase.instance.ref("App").child("AllPosts");
  //     if (_postId.isEmpty) {
  //       _postId = postsRef.push().key!;
  //     }
  //     List<String> imageUrls = [];
  //     for (final img in _imageFiles) {
  //       final upload = FirebaseStorage.instance
  //           .ref()
  //           .child('post_images')
  //           .child('$_postId${img.path.split('/').last}')
  //           .putFile(img);
  //       final snap = await upload;
  //       imageUrls.add(await snap.ref.getDownloadURL());
  //     }
  //     List<String> videoUrls = [];
  //     for (final vid in _videoFiles) {
  //       final upload = FirebaseStorage.instance
  //           .ref()
  //           .child('post_videos')
  //           .child('$_postId${vid.path.split('/').last}')
  //           .putFile(vid);
  //       final snap = await upload;
  //       videoUrls.add(await snap.ref.getDownloadURL());
  //     }
  //     String estateName;
  //     if (userType == "2" && selectedEstate.isNotEmpty) {
  //       estateName = selectedEstate['data']['NameEn'];
  //     } else if (userSnap.exists) {
  //       final u = userSnap.value as Map<dynamic, dynamic>;
  //       estateName = '${u['FirstName']} ${u['SecondName']} ${u['LastName']}';
  //     } else {
  //       estateName = 'Unknown User';
  //     }
  //     await postsRef.child(_postId).set({
  //       'Description': _titleController.text,
  //       'Date': DateTime.now().millisecondsSinceEpoch,
  //       'Username': estateName,
  //       'EstateType': selectedEstate['type'],
  //       'userId': userId,
  //       'userType': userType,
  //       'typeAccount': typeAccount,
  //       'ImageUrls': imageUrls,
  //       'VideoUrls': videoUrls,
  //       'ProfileImageUrl': profileImageUrl,
  //       'likes': {'count': 0, 'users': {}},
  //       'comments': {'count': 0, 'list': {}},
  //       'Status': isSuperUser ? '1' : '0',
  //     });
  //     await showDialog(
  //       context: context,
  //       builder: (_) => isSuperUser
  //           ? const SuccessDialog(
  //         text: "Success",
  //         text1: "Your post has been approved and is now visible.",
  //       )
  //           : const UnderProcessDialog(
  //         text: "Under Process",
  //         text1: "Your post is under process for review",
  //       ),
  //     );
  //     Navigator.of(context).pop();
  //   } catch (e) {
  //     await showDialog(
  //       context: context,
  //       builder: (_) => const FailureDialog(
  //         text: "Error",
  //         text1: "Failed to add post",
  //       ),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

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
    final hasMedia = _existingImageUrls.isNotEmpty ||
        _imageFiles.isNotEmpty ||
        _existingVideoUrls.isNotEmpty ||
        _videoFiles.isNotEmpty;

    if (!hasMedia) {
      return Container(
        alignment: Alignment.center,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? Colors.black12 : Colors.grey[200],
        ),
        child: Text(
          getTranslated(context, 'No media selected.'),
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    List<Widget> existingThumbs = [
      for (final url in _existingImageUrls)
        _removableThumb(
          child: Image.network(url, fit: BoxFit.cover, width: 150),
          onRemove: () => setState(() => _existingImageUrls.remove(url)),
        ),
      for (final url in _existingVideoUrls)
        _removableThumb(
          child: Container(
            width: 150,
            color: Colors.grey[800],
            child:
                const Center(child: Icon(Icons.videocam, color: Colors.white)),
          ),
          onRemove: () => setState(() => _existingVideoUrls.remove(url)),
        ),
      for (final file in _videoFiles)
        _removableThumb(
          child: Container(
            width: 150,
            color: Colors.grey[800],
            child:
                const Center(child: Icon(Icons.videocam, color: Colors.white)),
          ),
          onRemove: () => setState(() => _videoFiles.remove(file)),
        ),
    ];

    Widget newImageSection = const SizedBox.shrink();
    if (_imageFiles.isNotEmpty) {
      newImageSection = SizedBox(
        height: 150,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ReorderableWrap(
            spacing: 8,
            runSpacing: 8,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final file = _imageFiles.removeAt(oldIndex);
                _imageFiles.insert(newIndex, file);
              });
            },
            children: [
              for (int i = 0; i < _imageFiles.length; i++)
                KeyedSubtree(
                  key: ValueKey(_imageFiles[i].path),
                  child: _removableThumb(
                    child: Image.file(_imageFiles[i],
                        fit: BoxFit.cover, width: 150),
                    onRemove: () => setState(() => _imageFiles.removeAt(i)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget existingSection = existingThumbs.isNotEmpty
        ? SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: existingThumbs,
            ),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageFiles.isNotEmpty) newImageSection,
        if (existingThumbs.isNotEmpty) existingSection,
      ],
    );
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

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
