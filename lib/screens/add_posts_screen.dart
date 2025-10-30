// add_post_screen.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderables/reorderables.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  String? _selectedEstate; // estate key (id under App/Estate/<Type>/<id>)
  List<Map<dynamic, dynamic>> _userEstates = [];
  String userType = "2";
  String? typeAccount;

  // Scope: if this device is restricted to a single estate, enforce it here
  String?
      _scopedEstateId; // the IDEstate (not the node key) we’re allowed to post for
  bool _lockToScopedEstate = false;

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
      _loadDeviceScope(),
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

  /// Read device scope from App/User/<uid>/Tokens/<token>/scope
  /// If scope.type == 'estate', only allow posting for that single estate.
  Future<void> _loadDeviceScope() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseMessaging.instance.getToken();
      if (uid == null || token == null) return;

      final scopeRef =
          FirebaseDatabase.instance.ref('App/User/$uid/Tokens/$token/scope');
      final snap = await scopeRef.get();
      if (snap.exists) {
        final type = snap.child('type').value?.toString();
        final estId = snap.child('estateId').value?.toString();
        if (type == 'estate' && estId != null && estId.isNotEmpty) {
          _scopedEstateId = estId; // this is IDEstate
          _lockToScopedEstate = true;
        }
      }
    } catch (_) {}
  }

  /// Fetch accepted estates owned by the user.
  /// If device is estate-scoped, include **only that estate**.
  Future<void> _fetchUserEstates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseDatabase.instance.ref('App/Estate').once();
    final data = snap.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    final estates = <Map<dynamic, dynamic>>[];
    data.forEach((estateType, estatesMap) {
      if (estatesMap is Map) {
        estatesMap.forEach((nodeKey, value) {
          if (value != null &&
              value['IDUser'] == user.uid &&
              value['IsAccepted'] == "2") {
            // IDEstate stored in booking/posts; nodeKey is the DB key under /Estate/<type>/
            final ide = value['IDEstate']?.toString();
            // If scoped to a single estate, keep only that IDEstate
            if (_scopedEstateId != null && ide != _scopedEstateId) return;

            estates.add({
              'type': estateType, // Coffee / Hottel / Restaurant
              'data': value, // full estate map
              'id': nodeKey, // node key under Estate/<type>/
              'IDEstate': ide, // the public IDEstate used across app
              'NameEn': value['NameEn']?.toString() ?? '',
            });
          }
        });
      }
    });

    // If device is scoped but we didn’t find that estate (e.g., not accepted),
    // keep list empty so user can’t post.
    setState(() {
      _userEstates = estates;

      // If editing an existing post, don't override selection.
      if (widget.post == null) {
        if (_lockToScopedEstate && _scopedEstateId != null) {
          // find the entry matching IDEstate == scoped id
          final found = estates.firstWhere(
            (e) => e['IDEstate'] == _scopedEstateId,
            orElse: () => {},
          );
          _selectedEstate = found.isNotEmpty ? found['id'] as String : null;
        } else if (userType == '2' && estates.isNotEmpty) {
          _selectedEstate = estates.first['id'];
        }
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
    // 1) Super-user restriction (kept as in your original)
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

    // 2) Validate form + estate selection
    if (!_formKey.currentState!.validate() ||
        (userType != "1" && _selectedEstate == null)) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text: "Error",
          text1: "User not authenticated",
        ),
      );
      return;
    }
    final userId = user.uid;
    final isSuperUser = userId == _superUserId;

    // 3) Enforce device scope: if scoped to estate X, only allow posting for that estate
    if (_lockToScopedEstate && _scopedEstateId != null) {
      final selected = _userEstates.firstWhere(
        (e) => e['id'] == _selectedEstate,
        orElse: () => {},
      );
      final selectedIDEstate =
          selected.isNotEmpty ? selected['IDEstate'] : null;
      if (selectedIDEstate != _scopedEstateId) {
        showDialog(
          context: context,
          builder: (_) => const FailureDialog(
            text: "Not allowed",
            text1:
                "This device is restricted to a specific estate. Please post only for that estate.",
          ),
        );
        return;
      }
    }

    // 4) Post-limit check for non-super-users
    if (!isSuperUser && !await _canAddMorePosts()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 5) Fetch user profile image URL
      String? profileImageUrl;
      final userSnap =
          await FirebaseDatabase.instance.ref("App/User/$userId").get();
      if (userSnap.exists) {
        final userData = userSnap.value as Map<dynamic, dynamic>;
        profileImageUrl = userData['ProfileImageUrl'] as String?;
      }

      // 6) Find selected estate data (if provider)
      Map<dynamic, dynamic>? selectedEstateData;
      if (_selectedEstate != null) {
        selectedEstateData = _userEstates.firstWhere(
          (e) => e['id'] == _selectedEstate,
          orElse: () => {},
        );
        if (selectedEstateData.isEmpty) {
          showDialog(
            context: context,
            builder: (_) => const FailureDialog(
              text: "Error",
              text1: "You don't have this estate",
            ),
          );
          return;
        }
      }

      // 7) Prepare database reference & new post ID
      final postsRef = FirebaseDatabase.instance.ref("App/AllPosts");
      if (_postId.isEmpty) {
        _postId = postsRef.push().key!;
      }

      // 8) Compute total bytes for progress
      int totalBytes = 0;
      for (final f in [..._imageFiles, ..._videoFiles]) {
        totalBytes += await f.length();
      }
      int cumulativeTransferred = 0;

      // 9) Upload images with aggregated progress
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
            _uploadProgress = totalBytes == 0
                ? 0
                : (cumulativeTransferred + current) / totalBytes;
          });
        });

        await uploadTask;
        await subscription.cancel();

        cumulativeTransferred += fileBytes;
        imageUrls.add(await storageRef.getDownloadURL());
      }

      // 10) Upload videos with aggregated progress
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
            _uploadProgress = totalBytes == 0
                ? 0
                : (cumulativeTransferred + current) / totalBytes;
          });
        });

        await uploadTask;
        await subscription.cancel();

        cumulativeTransferred += fileBytes;
        videoUrls.add(await storageRef.getDownloadURL());
      }

      // 11) Determine display name
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

      // 12) Write post to Realtime Database
      await postsRef.child(_postId).set({
        'Description': _titleController.text.trim(),
        'Text': _textController.text.trim(),
        'Date': DateTime.now().millisecondsSinceEpoch,
        'Username': estateName,
        'EstateType': selectedEstateData?['type'],
        'EstateID': selectedEstateData?['IDEstate'], // IDEstate (public id)
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

      // 13) Dialogs
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

  Widget _buildEstateDropdown(bool isDark) {
    // If the device is locked to one estate, disable changing it
    final isDisabled = _lockToScopedEstate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedEstate,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? kDarkModeColor : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          hint: Text(getTranslated(context, 'Select Estate')),
          items: _userEstates.map((e) {
            final name = (e['NameEn'] as String?) ?? '';
            final type = (e['type'] as String?) ?? '';
            return DropdownMenuItem<String>(
              value: e['id'],
              child: Text('$name ($type)', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged:
              isDisabled ? null : (v) => setState(() => _selectedEstate = v),
          validator: (v) {
            if (userType == '2' && v == null) {
              return getTranslated(context, 'Please select an estate');
            }
            return null;
          },
        ),
        if (_lockToScopedEstate)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              getTranslated(context, 'Add post for your estate'),
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
      ],
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
          style: const TextStyle(color: kDeepPurpleColor),
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
