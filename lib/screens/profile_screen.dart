// lib/screens/profile_screen_user.dart

import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
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
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Image + loading states
  Uint8List? _image;
  String? _profileImageUrl;
  bool _isLoading = true;

  // Email-verified flag
  bool _isEmailVerified = false;

  // Services
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
    _secondNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
      _isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final imageUrl =
          await _profilePictureService.uploadImageToStorage(im, userId);
      if (imageUrl.isNotEmpty) {
        await _profilePictureService.saveImageUrlToDatabase(userId, imageUrl);
        await _profilePictureService.updateProfilePictureInPosts(
            userId, imageUrl);
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfileImage() async {
    final userInfo = await _userInfoService.fetchUserInfo();
    final profileImage = userInfo['ProfileImageUrl'];
    if (profileImage != null && profileImage.isNotEmpty) {
      setState(() => _profileImageUrl = profileImage);
    }
  }

  Future<void> afterLayoutWidgetBuild() async {
    // Load picture & user info
    await _loadProfileImage();

    // Reload Firebase user to get latest emailVerified
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      _isEmailVerified = user.emailVerified;
    }

    // Fetch other details
    final userInfo = await _userInfoService.fetchUserInfo();
    setState(() {
      _firstNameController.text = userInfo['FirstName'] ?? '';
      _secondNameController.text = userInfo['SecondName'] ?? '';
      _lastNameController.text = userInfo['LastName'] ?? '';
      _emailController.text = userInfo['Email'] ?? '';
      _phoneController.text = userInfo['PhoneNumber'] ?? '';
      _countryController.text = userInfo['Country'] ?? '';
      _cityController.text = userInfo['City'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(getTranslated(context, 'Verification Email Sent')),
            content: Text(getTranslated(context,
                'Please check your inbox (and spam folder) to verify your email.')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(getTranslated(context, 'OK')),
              ),
            ],
          ),
        );
      } catch (e) {
        showErrorDialog(
          context,
          getTranslated(context, 'Failed to send verification email.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          getTranslated(context, 'Profile'),
          style: const TextStyle(color: kDeepPurpleColor),
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
                // Profile picture + picker
                Stack(
                  children: [
                    _isLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: const CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: _profileImageUrl ?? '',
                            imageBuilder: (ctx, img) => CircleAvatar(
                              radius: 64,
                              backgroundImage: img,
                              backgroundColor: Colors.transparent,
                            ),
                            placeholder: (ctx, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: const CircleAvatar(
                                radius: 64,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                            errorWidget: (ctx, url, err) => const CircleAvatar(
                              radius: 64,
                              backgroundImage:
                                  AssetImage('assets/images/man.png'),
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
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
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
                    if (result == true) afterLayoutWidgetBuild();
                  },
                ),

                32.kH,

                // First Name
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

                // Second Name
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

                // Last Name
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

                // **Email** + verification indicator
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _emailController,
                          textInputType: TextInputType.emailAddress,
                          iconData: Icons.email,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ProfileInfoTextField(
                              textEditingController: _emailController,
                              textInputType: TextInputType.emailAddress,
                              iconData: Icons.email,
                              iconColor: kDeepPurpleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isEmailVerified
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : TextButton(
                                  onPressed: _sendVerificationEmail,
                                  child: Text(
                                    getTranslated(context, 'Verify Email'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                ),
                        ],
                      ),

                24.kH,

                // Phone
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ProfileInfoTextField(
                          textEditingController: _phoneController,
                          textInputType: TextInputType.phone,
                          iconData: Icons.phone,
                          iconColor: kDeepPurpleColor,
                        ),
                      )
                    : ProfileInfoTextField(
                        textEditingController: _phoneController,
                        textInputType: TextInputType.phone,
                        iconData: Icons.phone,
                        iconColor: kDeepPurpleColor,
                      ),

                24.kH,

                // Country
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

                // City
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
