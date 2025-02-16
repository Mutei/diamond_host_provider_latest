// lib/widgets/reaction_picker.dart

import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final List<String> reactions;
  final VoidCallback onAddEmoji;
  final void Function(String) onReactionSelected;

  const ReactionPicker({
    Key? key,
    required this.reactions,
    required this.onAddEmoji,
    required this.onReactionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: AlwaysStoppedAnimation(1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reactions.map((reaction) {
                return GestureDetector(
                  onTap: () => onReactionSelected(reaction),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      reaction,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }).toList(),
              GestureDetector(
                onTap: onAddEmoji,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.add, size: 24, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
