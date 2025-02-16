import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';

class MusicVisibility extends StatefulWidget {
  final bool isVisible;
  final bool checkMusic;
  final bool haveMusic;
  final bool haveSinger;
  final bool haveDJ;
  final bool haveOud;
  final Function(bool) onMusicChanged;
  final Function(bool) onSingerChanged;
  final Function(bool) onDJChanged;
  final Function(bool) onOudChanged;

  const MusicVisibility({
    super.key,
    required this.isVisible,
    required this.checkMusic,
    required this.haveMusic,
    required this.haveSinger,
    required this.haveDJ,
    required this.haveOud,
    required this.onMusicChanged,
    required this.onSingerChanged,
    required this.onDJChanged,
    required this.onOudChanged,
  });

  @override
  _MusicVisibilityState createState() => _MusicVisibilityState();
}

class _MusicVisibilityState extends State<MusicVisibility> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(getTranslated(context, "Is there music")),
            ),
            Expanded(
              child: Checkbox(
                checkColor: Colors.white,
                value: widget.checkMusic,
                onChanged: (bool? value) {
                  widget.onMusicChanged(value!);
                },
                activeColor: kPurpleColor,
              ),
            ),
          ],
        ),
        if (widget.haveMusic)
          Column(
            children: [
              _buildCheckboxRow(
                context,
                'singer',
                widget.haveSinger,
                (value) {
                  widget.onSingerChanged(value);
                },
              ),
              _buildCheckboxRow(
                context,
                'DJ',
                widget.haveDJ,
                (value) {
                  widget.onDJChanged(value);
                },
              ),
              _buildCheckboxRow(
                context,
                'Oud',
                widget.haveOud,
                (value) {
                  widget.onOudChanged(value);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            getTranslated(context, label),
          ),
        ),
        Expanded(
          child: Checkbox(
            checkColor: Colors.white,
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue!),
            activeColor: kPurpleColor,
          ),
        ),
      ],
    );
  }
}
