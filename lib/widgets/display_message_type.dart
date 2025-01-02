import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';

class DisplayMessageType extends StatelessWidget {
  const DisplayMessageType({
    super.key,
    required this.message,
    required this.type,
    required this.color,
    this.maxLines,
    this.overflow,
  });

  final String message;
  final MessageEnum type;
  final Color color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    Widget messageToShow() {
      switch (type) {
        case MessageEnum.text:
          return Text(
            message,
            maxLines: maxLines,
            overflow: overflow,
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          );
        case MessageEnum.image:
          // return Image.network(
          //   message,
          //   fit: BoxFit.cover,
          // );
          return CachedNetworkImage(
            imageUrl: message,
            fit: BoxFit.cover,
          );
        // case MessageEnum.video:
        //   return VideoPlayerWidget(
        //     videoUrl: message,
        //     color: color,
        //   );
        case MessageEnum.file:
          return CachedNetworkImage(
            imageUrl: message,
            fit: BoxFit.cover,
          );
        default:
          return Text(
            message,
            maxLines: maxLines,
            overflow: overflow,
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          );
      }
    }

    return messageToShow();
  }
}
