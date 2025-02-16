import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../backend/profile_picture_services.dart';
import '../backend/profile_user_info_services.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/global_methods.dart';
import '../widgets/profile_info_text_field.dart';
import '../widgets/reused_elevated_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreenUser extends StatefulWidget {
  const ProfileScreenUser({super.key});

  @override
  State<ProfileScreenUser> createState() => _ProfileScreenUserState();
}

class _ProfileScreenUserState extends State<ProfileScreenUser> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  Uint8List? _image;
  String? _profileImageUrl;
  bool _isLoading = true; // Show shimmer until data is fetched

  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final UserInfoService _userInfoService = UserInfoService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterLayoutWidgetBuild());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
      _isLoading = true; // Start shimmer loading
    });

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // Upload image and update the profile picture in Firebase
      String imageUrl =
          await _profilePictureService.uploadImageToStorage(im, userId);
      if (imageUrl.isNotEmpty) {
        await _profilePictureService.saveImageUrlToDatabase(userId, imageUrl);
        await _profilePictureService.updateProfilePictureInPosts(
            userId, imageUrl);

        print("Image uploaded to URL: $imageUrl");

        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false; // Stop shimmer loading
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final userInfo = await _userInfoService.fetchUserInfo();
    final profileImageUrl = userInfo['ProfileImageUrl'];
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = profileImageUrl;
      });
    }
  }

  void afterLayoutWidgetBuild() async {
    await _loadProfileImage();
    Map<String, String?> userInfo = await _userInfoService.fetchUserInfo();
    setState(() {
      _firstNameController.text = userInfo['FirstName'] ?? '';
      _secondNameController.text = userInfo['SecondName'] ?? '';
      _lastNameController.text = userInfo['LastName'] ?? '';
      _emailController.text = userInfo['Email'] ?? '';
      _phoneController.text = userInfo['PhoneNumber'] ?? '';
      _countryController.text = userInfo['Country'] ?? '';
      _cityController.text = userInfo['City'] ?? '';
      _isLoading = false; // Stop shimmer loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          getTranslated(context, 'Profile'),
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
        iconTheme: kIconTheme,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    _isLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: _profileImageUrl ?? '',
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 64,
                              backgroundImage: imageProvider,
                              backgroundColor: Colors.transparent,
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: CircleAvatar(
                                radius: 64,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 64,
                              backgroundImage:
                                  const AssetImage('assets/images/man.png')
                                      as ImageProvider,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: selectImage,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
                16.kH,
                CustomButton(
                  text: getTranslated(context, 'Edit Profile'),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          firstName: _firstNameController.text,
                          secondName: _secondNameController.text,
                          lastName: _lastNameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          country: _countryController.text,
                          city: _cityController.text,
                        ),
                      ),
                    );
                    if (result == true) {
                      afterLayoutWidgetBuild();
                    }
                  },
                ),
                32.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _firstNameController,
                          textInputType: TextInputType.text,
                          iconData: Icons.person,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _firstNameController,
                        textInputType: TextInputType.text,
                        iconData: Icons.person,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _secondNameController,
                          textInputType: TextInputType.text,
                          iconData: Icons.person,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _secondNameController,
                        textInputType: TextInputType.text,
                        iconData: Icons.person,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _lastNameController,
                          textInputType: TextInputType.text,
                          iconData: Icons.person,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _lastNameController,
                        textInputType: TextInputType.text,
                        iconData: Icons.person,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _emailController,
                          textInputType: TextInputType.text,
                          iconData: Icons.email,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _emailController,
                        textInputType: TextInputType.text,
                        iconData: Icons.email,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _phoneController,
                          textInputType: TextInputType.text,
                          iconData: Icons.phone,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _phoneController,
                        textInputType: TextInputType.text,
                        iconData: Icons.phone,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _countryController,
                          textInputType: TextInputType.text,
                          iconData: Icons.location_city,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _countryController,
                        textInputType: TextInputType.text,
                        iconData: Icons.location_city,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _cityController,
                          textInputType: TextInputType.text,
                          iconData: Icons.location_city,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _cityController,
                        textInputType: TextInputType.text,
                        iconData: Icons.location_city,
                        iconColor: kDeepPurpleColor,
                      ),
                24.kH,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
