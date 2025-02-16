import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'dart:io';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your localization helper
import 'package:daimond_host_provider/localization/language_constants.dart';

class ReusedAllPostsCards extends StatefulWidget {
  final Map post;
  final String? currentUserId;
  final String? currentUserProfileImage;
  final String? currentUserTypeAccount;
  final VoidCallback onDelete;

  const ReusedAllPostsCards({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.currentUserProfileImage,
    required this.currentUserTypeAccount,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ReusedAllPostsCardsState createState() => _ReusedAllPostsCardsState();
}

class _ReusedAllPostsCardsState extends State<ReusedAllPostsCards> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;
  List<Map<String, dynamic>> commentsList = [];
  String userType = "2";
  List<Map<dynamic, dynamic>> _userEstates = [];
  Map<String, TextEditingController> _replyControllers = {};

  // State Variables for "View All Comments" Feature
  bool _showAllComments = false;
  final int _commentsToShow = 2; // Number of comments to show initially

  // State Variable to Track Visible Replies
  Set<String> _visibleReplies = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserType();
    _fetchUserEstates();

    // Initialize video controller if the post contains videos
    if (widget.post['VideoUrls'] != null &&
        widget.post['VideoUrls'].isNotEmpty) {
      _initializeVideoController(widget.post['VideoUrls'][0]);
    }

    // Listen to changes in likes and comments
    _listenToLikes();
    _listenToComments();
  }

  Future<void> _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString("TypeUser") ?? "2";
    });
  }

  Future<void> _fetchUserEstates() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String userId = user.uid;

    DatabaseReference estateRef =
        FirebaseDatabase.instance.ref("App").child("Estate");
    DatabaseEvent estateEvent = await estateRef.once();
    Map<dynamic, dynamic>? estatesData =
        estateEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (estatesData != null) {
      List<Map<dynamic, dynamic>> userEstates = [];
      estatesData.forEach((estateType, estates) {
        if (estates is Map<dynamic, dynamic>) {
          estates.forEach((key, value) {
            if (value != null &&
                value['IDUser'] == userId &&
                value['IsAccepted'] == "2") {
              userEstates.add({'type': estateType, 'data': value, 'id': key});
            }
          });
        }
      });

      setState(() {
        _userEstates = userEstates;
      });
    }
  }

  void _initializeVideoController(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play(); // Automatically play the video
      });
  }

  void _listenToLikes() {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    postRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map likesData = event.snapshot.value as Map;
        setState(() {
          likeCount = likesData['count'] ?? 0;
          isLiked = likesData['users']?[userId] ?? false;
        });
      } else {
        setState(() {
          likeCount = 0;
          isLiked = false;
        });
      }
    });
  }

  void _listenToComments() {
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/comments/list');

    commentsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic>? commentsData =
            event.snapshot.value as Map<dynamic, dynamic>?;

        if (commentsData == null) {
          setState(() {
            commentsList = [];
          });
          return;
        }

        List<Map<String, dynamic>> fetchedComments = [];

        commentsData.forEach((commentId, commentData) {
          if (commentData is Map<dynamic, dynamic>) {
            Map<String, dynamic> comment =
                Map<String, dynamic>.from(commentData);

            // Handle 'replies'
            if (comment.containsKey('replies') && comment['replies'] is Map) {
              Map<dynamic, dynamic> repliesData =
                  comment['replies'] as Map<dynamic, dynamic>;
              List<Map<String, dynamic>> repliesList = [];

              repliesData.forEach((replyId, replyData) {
                if (replyData is Map<dynamic, dynamic>) {
                  Map<String, dynamic> reply =
                      Map<String, dynamic>.from(replyData);
                  reply['id'] = replyId;
                  repliesList.add(reply);
                }
              });

              comment['replies'] = repliesList;
            } else {
              // If 'replies' is null or not a map, set it to an empty list
              comment['replies'] = [];
            }

            comment['id'] = commentId;
            fetchedComments.add(comment);
          }
        });

        // Optionally, sort comments by timestamp descending
        fetchedComments
            .sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          commentsList = fetchedComments;
        });
      } else {
        setState(() {
          commentsList = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _commentController.dispose();
    // Dispose all reply controllers
    _replyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Method to handle like button press
  void _handleLike() async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    await postRef.runTransaction((data) {
      Map<dynamic, dynamic> likesData =
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}};

      int currentLikeCount = likesData['count'] ?? 0;
      Map<dynamic, dynamic> usersMap =
          Map<String, dynamic>.from(likesData['users'] ?? {});

      if (usersMap.containsKey(userId)) {
        usersMap.remove(userId);
        currentLikeCount = (currentLikeCount > 0) ? currentLikeCount - 1 : 0;
      } else {
        usersMap[userId] = true;
        currentLikeCount += 1;
      }

      likesData['count'] = currentLikeCount;
      likesData['users'] = usersMap;

      return Transaction.success(likesData);
    });
  }

  // Method to add a comment to a post
  void _addComment(String postId, String commentText) async {
    String userId = widget.currentUserId ?? '';
    String? selectedEstate;

    // Prompt user to select an estate if they are a provider
    if (userType == "2") {
      selectedEstate = await _selectEstate();
      if (selectedEstate == null) return; // Exit if no estate is selected
    } else {
      selectedEstate = widget.post['Username'] ?? 'Unknown Estate';
    }

    // Use the current user's profile image instead of the post owner's
    String estateProfileImageUrl = widget.currentUserProfileImage ?? '';

    DatabaseReference commentsRef =
        FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/list');
    String? commentId = commentsRef.push().key;

    if (commentId != null) {
      await commentsRef.child(commentId).set({
        'text': commentText,
        'userId': userId,
        'userName': selectedEstate,
        'userProfileImage': estateProfileImageUrl, // Updated here
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': {
          'count': 0,
          'users': {},
        },
        'replies': {},
      });

      DatabaseReference commentCountRef =
          FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/count');
      await commentCountRef.set(ServerValue.increment(1));

      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, 'Failed to add comment')),
        ),
      );
    }
  }

  // Method to select an estate (used for providers)
  Future<String?> _selectEstate() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? selectedEstate;
        return AlertDialog(
          title: Text(getTranslated(context, "Select Estate")),
          content: DropdownButtonFormField<String>(
            value: selectedEstate,
            hint: Text(getTranslated(context, "Choose an Estate")),
            items: _userEstates.map((estate) {
              return DropdownMenuItem<String>(
                value: estate['data']['NameEn'],
                child: Text(estate['data']['NameEn']),
              );
            }).toList(),
            onChanged: (value) {
              selectedEstate = value;
            },
          ),
          actions: [
            TextButton(
              child: Text(getTranslated(context, "Cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(getTranslated(context, "Confirm")),
              onPressed: () {
                Navigator.of(context).pop(selectedEstate);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to build the profile section at the top of each post
  Widget _buildProfileSection() {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.post['ProfileImageUrl'] != null &&
                widget.post['ProfileImageUrl'].isNotEmpty
            ? CachedNetworkImageProvider(widget.post['ProfileImageUrl'])
            : const AssetImage('assets/images/default.jpg') as ImageProvider,
        radius: 30,
      ),
      title: Text(
        widget.post['Username'] ?? 'Unknown Estate',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        widget.post['RelativeDate'] ?? 'Unknown Date',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: widget.currentUserId == widget.post['userId']
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Delete'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(getTranslated(context, choice)),
                  );
                }).toList();
              },
            )
          : null,
    );
  }

  // Method to build the action buttons (like, comment)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: _handleLike,
            child: IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: _handleLike,
            ),
          ),
          Text(
            '$likeCount',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () {
              // Optionally, scroll to comment section or focus on comment field
            },
          ),
          Text(
            '${commentsList.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _addReply(String postId, String commentId, String replyText) async {
    String userId = widget.currentUserId ?? '';
    String? selectedEstate;

    // Prompt user to select an estate if they are a provider
    if (userType == "2") {
      selectedEstate = await _selectEstate();
      if (selectedEstate == null) return; // Exit if no estate is selected
    } else {
      selectedEstate = widget.post['Username'] ?? 'Unknown Estate';
    }

    // Use the current user's profile image instead of the post owner's
    String estateProfileImageUrl = widget.currentUserProfileImage ?? '';

    DatabaseReference repliesRef = FirebaseDatabase.instance
        .ref('App/AllPosts/$postId/comments/list/$commentId/replies');
    String? replyId = repliesRef.push().key;

    if (replyId != null) {
      await repliesRef.child(replyId).set({
        'text': replyText,
        'userId': userId,
        'userName': selectedEstate,
        'userProfileImage': estateProfileImageUrl, // Updated here
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': {
          'count': 0,
          'users': {},
        },
      });

      // Optionally, update reply count
      DatabaseReference replyCountRef = FirebaseDatabase.instance
          .ref('App/AllPosts/$postId/comments/list/$commentId/replyCount');
      await replyCountRef.set(ServerValue.increment(1));

      // Optionally, update UI or notify user
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, 'Failed to add reply')),
        ),
      );
    }
  }

  // Method to handle like/unlike on a reply
  void _handleLikeReply(String postId, String commentId, String replyId) async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference likeRef = FirebaseDatabase.instance.ref(
        'App/AllPosts/$postId/comments/list/$commentId/replies/$replyId/likes');

    await likeRef.runTransaction((data) {
      Map<dynamic, dynamic> likesData =
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}};

      int currentLikeCount = likesData['count'] ?? 0;
      Map<dynamic, dynamic> usersMap =
          Map<String, dynamic>.from(likesData['users'] ?? {});

      if (usersMap.containsKey(userId)) {
        usersMap.remove(userId);
        currentLikeCount = (currentLikeCount > 0) ? currentLikeCount - 1 : 0;
      } else {
        usersMap[userId] = true;
        currentLikeCount += 1;
      }

      likesData['count'] = currentLikeCount;
      likesData['users'] = usersMap;

      return Transaction.success(likesData);
    });
  }

  // Method to handle like/unlike on a comment
  void _handleLikeComment(String postId, String commentId) async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference likeRef = FirebaseDatabase.instance
        .ref('App/AllPosts/$postId/comments/list/$commentId/likes');

    await likeRef.runTransaction((data) {
      Map<dynamic, dynamic> likesData =
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}};

      int currentLikeCount = likesData['count'] ?? 0;
      Map<dynamic, dynamic> usersMap =
          Map<String, dynamic>.from(likesData['users'] ?? {});

      if (usersMap.containsKey(userId)) {
        usersMap.remove(userId);
        currentLikeCount = (currentLikeCount > 0) ? currentLikeCount - 1 : 0;
      } else {
        usersMap[userId] = true;
        currentLikeCount += 1;
      }

      likesData['count'] = currentLikeCount;
      likesData['users'] = usersMap;

      return Transaction.success(likesData);
    });
  }

  // Method to build the text content of the post
  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        widget.post['Description'] ?? '',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Method to build the images and videos in the post

  Widget _buildImageVideoContent() {
    List imageUrls = widget.post['ImageUrls'] ?? [];
    List videoUrls = widget.post['VideoUrls'] ?? [];

    if (imageUrls.isEmpty && videoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imageUrls.length + videoUrls.length,
        itemBuilder: (context, index) {
          if (index < imageUrls.length) {
            // Use Shimmer for the loading effect instead of CircularProgressIndicator
            return CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                  height: 300,
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            );
          } else {
            String videoUrl = videoUrls[index - imageUrls.length];
            VideoPlayerController videoController =
                VideoPlayerController.network(videoUrl);
            return FutureBuilder(
              future: videoController.initialize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  videoController.setLooping(true);
                  videoController.play();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        videoController.value.isPlaying
                            ? videoController.pause()
                            : videoController.play();
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    ),
                  );
                } else {
                  // Show shimmer effect while video is loading
                  return Center(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey,
                      highlightColor: Colors.white,
                      child: Container(
                        color: Colors.grey,
                        width: double.infinity,
                        height: 300,
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  // Method to build the comment section with "View All Comments" and "Hide Comments" functionality
  Widget _buildCommentSection() {
    // Determine the number of comments to display
    int commentsToShow =
        _showAllComments ? commentsList.length : _commentsToShow;
    List<Map<String, dynamic>> commentsToDisplay =
        commentsList.take(commentsToShow).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display each comment with replies
          ...commentsToDisplay
              .map((comment) => _buildCommentItem(comment))
              .toList(),

          // "View All Comments" or "Hide Comments" Button
          if (commentsList.length > _commentsToShow)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllComments = !_showAllComments;
                  });
                },
                child: Text(
                  _showAllComments
                      ? getTranslated(context, 'Hide Comments')
                      : getTranslated(context, 'View All {count} Comments')
                          .replaceAll(
                          '{count}',
                          commentsList.length.toString(),
                        ),
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ),

          // Add Comment Input Field
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.currentUserProfileImage != null &&
                        widget.currentUserProfileImage!.isNotEmpty
                    ? NetworkImage(widget.currentUserProfileImage!)
                    : const AssetImage('assets/images/default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: getTranslated(context, 'Write a comment...'),
                    hintStyle:
                        TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    _addComment(
                        widget.post['postId'], _commentController.text.trim());
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to build an individual comment item
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    String profileImageUrl = comment['userProfileImage'] ?? '';
    String commentId = comment['id'] ?? '';

    bool areRepliesVisible = _visibleReplies.contains(commentId);
    bool hasReplies =
        comment['replies'] != null && comment['replies'].isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : const AssetImage('assets/images/default.jpg')
                    as ImageProvider,
          ),
          title: Text(
            comment['userName'] ?? 'Unknown Estate',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            comment['text'] ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Button for Comment
              IconButton(
                icon: Icon(
                  comment['likes'] != null &&
                          comment['likes']['users'] != null &&
                          widget.currentUserId != null &&
                          comment['likes']['users']
                              .containsKey(widget.currentUserId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: comment['likes'] != null &&
                          comment['likes']['users'] != null &&
                          widget.currentUserId != null &&
                          comment['likes']['users']
                              .containsKey(widget.currentUserId)
                      ? Colors.red
                      : Colors.grey,
                ),
                onPressed: () {
                  // Implement like/unlike for comment
                  _handleLikeComment(widget.post['postId'], commentId);
                },
              ),
              Text(
                '${comment['likes']?['count'] ?? 0}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        // Always show the reply input field, regardless of whether there are replies
        Padding(
          padding: const EdgeInsets.only(left: 60.0, right: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.currentUserProfileImage != null &&
                        widget.currentUserProfileImage!.isNotEmpty
                    ? NetworkImage(widget.currentUserProfileImage!)
                    : const AssetImage('assets/images/default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _replyControllers[commentId] ??
                      (_replyControllers[commentId] = TextEditingController()),
                  decoration: InputDecoration(
                    hintText: getTranslated(context, 'Write a reply...'),
                    hintStyle:
                        TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: () {
                  String replyText =
                      _replyControllers[commentId]?.text.trim() ?? '';
                  if (replyText.isNotEmpty) {
                    _addReply(widget.post['postId'], commentId, replyText);
                    setState(() {
                      _replyControllers[commentId]?.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Only show the "Show Replies" or "Hide Replies" button if there are replies
        if (hasReplies)
          Padding(
            padding: const EdgeInsets.only(left: 60.0, right: 12.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  if (areRepliesVisible) {
                    _visibleReplies.remove(commentId);
                  } else {
                    _visibleReplies.add(commentId);
                  }
                });
              },
              child: Text(
                areRepliesVisible
                    ? getTranslated(context, 'Hide Replies')
                    : getTranslated(context, 'Show Replies'),
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),

        // Replies Section
        if (hasReplies && areRepliesVisible)
          Padding(
            padding: const EdgeInsets.only(left: 60.0),
            child: Column(
              children: [
                // Display Replies
                if (comment['replies'] != null && comment['replies'].isNotEmpty)
                  ...comment['replies']
                      .map<Widget>((reply) => _buildReplyItem(reply, commentId))
                      .toList(),
                // Reply Input Field (Already displayed above, no need to duplicate)
              ],
            ),
          ),
      ],
    );
  }

  // Method to build an individual reply item
  Widget _buildReplyItem(Map<String, dynamic> reply, String commentId) {
    String replyProfileImageUrl = reply['userProfileImage'] ?? '';
    String replyId = reply['id'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundImage: replyProfileImageUrl.isNotEmpty
            ? NetworkImage(replyProfileImageUrl)
            : const AssetImage('assets/images/default.jpg') as ImageProvider,
      ),
      title: Text(
        reply['userName'] ?? 'Unknown Estate',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        reply['text'] ?? '',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like Button for Reply
          IconButton(
            icon: Icon(
              reply['likes'] != null &&
                      reply['likes']['users'] != null &&
                      widget.currentUserId != null &&
                      reply['likes']['users'].containsKey(widget.currentUserId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: reply['likes'] != null &&
                      reply['likes']['users'] != null &&
                      widget.currentUserId != null &&
                      reply['likes']['users'].containsKey(widget.currentUserId)
                  ? Colors.red
                  : Colors.grey,
            ),
            onPressed: () {
              // Implement like/unlike for reply
              _handleLikeReply(widget.post['postId'], commentId, replyId);
            },
          ),
          Text(
            '${reply['likes']?['count'] ?? 0}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleLike,
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkModeColor
            : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            if (widget.post['Description'] != null) _buildTextContent(),
            _buildImageVideoContent(),
            _buildActionButtons(),
            _buildCommentSection(),
          ],
        ),
      ),
    );
  }
}
