// lib/widgets/message_bubble.dart

import 'dart:async';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'reaction_picker.dart'; // Ensure this import path is correct
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';
import '../localization/language_constants.dart';

class MessageBubble extends StatefulWidget {
  final String messageId;
  final String estateId; // Now represents chatId
  final String senderId; // Updated to include senderId
  final String sender;
  final String text;
  final bool isMe;
  final String timestamp;
  final String profileImageUrl;
  final Map<String, int> reactions;
  final Map<String, dynamic>? replyTo;
  final Function(Map<String, dynamic>) onReply;
  final Function(String, {bool toggle}) onReact; // Updated to handle toggle
  final Stream<void> hideReactionPickersStream;

  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.estateId, // Now represents chatId
    required this.senderId, // Added senderId
    required this.sender,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.profileImageUrl,
    required this.reactions,
    this.replyTo,
    required this.onReply,
    required this.onReact,
    required this.hideReactionPickersStream,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isPredefinedReactionPickerVisible = false;
  bool _isEmojiPickerVisible = false;

  final List<String> _predefinedReactions = [
    '👍',
    '❤',
    '😂',
    '😮',
    '😢',
    '😡',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late StreamSubscription<void> _hideReactionPickersSubscription;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _hideReactionPickersSubscription =
        widget.hideReactionPickersStream.listen((_) {
      if (_isPredefinedReactionPickerVisible || _isEmojiPickerVisible) {
        setState(() {
          _isPredefinedReactionPickerVisible = false;
          _isEmojiPickerVisible = false;
        });
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideReactionPickersSubscription.cancel();
    super.dispose();
  }

  void _togglePredefinedReactionPicker() {
    setState(() {
      _isPredefinedReactionPickerVisible = !_isPredefinedReactionPickerVisible;
      if (_isPredefinedReactionPickerVisible) {
        _isEmojiPickerVisible = false;
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      if (_isEmojiPickerVisible) {
        _isPredefinedReactionPickerVisible = false;
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildReplyTo(Color bubbleColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: bubbleColor.withOpacity(0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.replyTo!['senderName'] ?? 'Anonymous',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blueAccent,
              fontFamily: 'Roboto', // Updated font family
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.replyTo!['text'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
              fontFamily: 'Roboto', // Updated font family
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Color bubbleColor, Color textColor, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(widget.isMe ? 16 : 0),
          bottomRight: Radius.circular(widget.isMe ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            widget.text.trim(), // Trim extra spaces from the message text
            style: TextStyle(
              fontFamily: 'Roboto', // Updated font family
              color: textColor,
              fontSize: 16,
              fontFamilyFallback: [
                'NotoColorEmoji',
                'Segoe UI Emoji',
                'Apple Color Emoji'
              ],
              wordSpacing: 0, // Adjust word spacing if needed
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: widget.isMe ? Colors.white70 : Colors.black54,
              fontFamily: 'Roboto', // Updated font family
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        children: widget.reactions.entries.map((entry) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto', // Updated font family
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'Roboto', // Updated font family
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reaction Button
        IconButton(
          icon: Icon(Icons.emoji_emotions_outlined,
              size: 24, color: Colors.grey[600]),
          onPressed: _togglePredefinedReactionPicker,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Reply Button
        IconButton(
          icon: Icon(Icons.reply, size: 24, color: Colors.grey[600]),
          onPressed: () => widget.onReply({
            'senderId': widget.senderId, // Updated senderId
            'senderName': widget.sender,
            'text': widget.text,
          }),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildPredefinedReactions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: ReactionPicker(
          reactions: _predefinedReactions,
          onReactionSelected: (reaction) {
            widget.onReact(reaction);
            setState(() {
              _isPredefinedReactionPickerVisible = false;
              _animationController.reverse();
            });
          },
          onAddEmoji: () {
            _togglePredefinedReactionPicker();
            _toggleEmojiPicker();
          },
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // child: SizedBox(
          //   height: 300,
          //   child: emoji_picker.EmojiPicker(
          //     onEmojiSelected: (category, emoji_picker.Emoji emoji) {
          //       setState(() {
          //         _isEmojiPickerVisible = false;
          //         _animationController.reverse();
          //       });
          //       widget.onReact(emoji.emoji);
          //     },
          //     config: emoji_picker.Config(
          //       columns: 8,
          //       emojiSizeMax: 32,
          //       verticalSpacing: 4,
          //       horizontalSpacing: 4,
          //       gridPadding: const EdgeInsets.all(8),
          //       initCategory: emoji_picker.Category.RECENT,
          //       bgColor: Colors.white,
          //       indicatorColor: Theme.of(context).primaryColor,
          //       iconColor: Colors.grey,
          //       iconColorSelected: Theme.of(context).primaryColor,
          //       backspaceColor: Theme.of(context).primaryColor,
          //       categoryIcons: const emoji_picker.CategoryIcons(),
          //       buttonMode: emoji_picker.ButtonMode.MATERIAL,
          //     ),
          //   ),
          // ),
        ),
      ),
    );
  }

  // void _showPrivateChatRequestDialog(
  //     String recipientId, String recipientName) async {
  //   final provider = Provider.of<GeneralProvider>(context, listen: false);
  //
  //   // Ensure senderId and senderName are not empty
  //   if (provider.userId.isEmpty || provider.userName.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(getTranslated(context, "User information is missing.")),
  //       ),
  //     );
  //     return;
  //   }
  //
  //   // Fetch the TypeAccount of the current user from Firebase
  //   final userRef =
  //       FirebaseDatabase.instance.ref('App/User/${provider.userId}');
  //   final snapshot = await userRef.get();
  //
  //   if (snapshot.exists) {
  //     final data = snapshot.value as Map;
  //     final typeAccount = data['TypeAccount']?.toString() ?? '';
  //
  //     // Check if TypeAccount is "1" and show an error message
  //     if (typeAccount == "1") {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(getTranslated(context,
  //               "Upgrade to Premium or Premium Plus to send private chat requests")),
  //         ),
  //       );
  //       return;
  //     }
  //
  //     // If TypeAccount is not "1", proceed to show the chat request dialog
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text(getTranslated(context, "Send Private Chat Request")),
  //           content: Text(
  //               "${getTranslated(context, "Do you want to send a private chat request to")} $recipientName?"),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: Text(getTranslated(context, "Cancel")),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //                 _sendPrivateChatRequest(
  //                     provider.userId, recipientId, recipientName);
  //               },
  //               child: Text(getTranslated(context, "Send")),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content:
  //             Text(getTranslated(context, "Failed to fetch user information.")),
  //       ),
  //     );
  //   }
  // }
  //
  // void _sendPrivateChatRequest(
  //     String senderId, String receiverId, String receiverName) async {
  //   try {
  //     await _privateChatService.sendPrivateChatRequest(
  //       senderId: senderId,
  //       receiverId: receiverId,
  //     );
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content:
  //               Text(getTranslated(context, 'Request sent successfully.'))),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text(getTranslated(context, 'Failed to send request.'))),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final formattedTime = widget.timestamp.isNotEmpty
        ? DateFormat('hh:mm a').format(DateTime.parse(widget.timestamp))
        : '';

    final ThemeData theme = Theme.of(context);
    final bubbleColor = widget.isMe
        ? Theme.of(context).brightness == Brightness.dark
            ? Colors.deepPurple
            : theme.primaryColor
        : Theme.of(context).brightness == Brightness.dark
            ? kDeepPurpleColor
            : Colors.grey[300];
    final textColor = widget.isMe
        ? Colors.white
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.isMe)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.profileImageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(widget.profileImageUrl)
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                ),
              if (!widget.isMe) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!widget.isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          widget.sender,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[700],
                            fontSize: 12,
                            fontFamily: 'Roboto', // Updated font family
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    if (widget.replyTo != null) _buildReplyTo(bubbleColor!),
                    _buildMessageBubble(bubbleColor!, textColor, formattedTime),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // _buildActions(context),
          // // if (widget.reactions.isNotEmpty) _buildReactions(),
          // // // Reaction Pickers
          // // if (_isPredefinedReactionPickerVisible) _buildPredefinedReactions(),
          // // if (_isEmojiPickerVisible) _buildEmojiPicker(),
        ],
      ),
    );
  }
}
