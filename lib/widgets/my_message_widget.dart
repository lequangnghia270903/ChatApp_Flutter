import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/widgets/display_message_type.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:translator/translator.dart';

class MyMessageWidget extends StatefulWidget {
  const MyMessageWidget({
    super.key,
    required this.message,
    required this.onLeftSwipe,
  });

  final MessageModel message;
  final Function() onLeftSwipe;

  @override
  State<MyMessageWidget> createState() => _MyMessageWidgetState();
}

class _MyMessageWidgetState extends State<MyMessageWidget> {
  final translator = GoogleTranslator(); // Đối tượng dịch

  bool _isTranslate = false;
  String _translatedText = '';

  bool _isVietnamese(String text) {
    // Kiểm tra xem văn bản có chứa ký tự tiếng Việt
    return RegExp(
            r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]')
        .hasMatch(text);
  }

  void _translateMessage() async {
    if (widget.message.messageType == MessageEnum.text && !_isTranslate) {
      final textToTranslate = widget.message.message;

      // Kiểm tra ngôn ngữ và dịch
      final toLanguage = _isVietnamese(textToTranslate) ? 'en' : 'vi';
      final translated =
          await translator.translate(textToTranslate, to: toLanguage);

      setState(() {
        _isTranslate = true;
        _translatedText = translated.text;
      });
    } else {
      setState(() {
        _isTranslate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = formatDate(widget.message.timeSent, [HH, ':', nn, ' ']);
    final isReplying = widget.message.repliedTo.isNotEmpty;

    return SwipeTo(
      onLeftSwipe: (details) {
        widget.onLeftSwipe();
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            minWidth: MediaQuery.of(context).size.width * 0.3,
          ),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: widget.message.messageType == MessageEnum.text
                  ? Colors.deepPurple // Màu nền cho tin nhắn văn bản
                  : Colors
                      .transparent, // Màu nền cho hình ảnh, video, hoặc âm thanh
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: widget.message.messageType == MessageEnum.text
                      ? const EdgeInsets.fromLTRB(10.0, 30.0, 20.0, 20.0)
                      : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isReplying) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColorDark
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.message.repliedTo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DisplayMessageType(
                                  message: widget.message.repliedMessage,
                                  type: widget.message.repliedMessageType,
                                  color: Colors.white,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      DisplayMessageType(
                        message: _isTranslate
                            ? _translatedText
                            : widget.message.message,
                        type: widget.message.messageType,
                        color: Colors.white,
                      ),
                      if (widget.message.messageType == MessageEnum.text)
                        GestureDetector(
                          onTap: _translateMessage,
                          child: Text(
                            _isTranslate ? 'Bản gốc' : 'Dịch',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 10,
                  child: Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: widget.message.messageType == MessageEnum.text
                              ? Colors.white // Màu cho tin nhắn văn bản
                              : Colors.black, // Màu cho tin nhắn hình ảnh
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        widget.message.isSeen ? Icons.done_all : Icons.done,
                        color: widget.message.messageType == MessageEnum.text
                            ? (widget.message.isSeen
                                ? Colors.blue
                                : Colors.white60) // Màu cho tin nhắn văn bản
                            : (widget.message.isSeen
                                ? Colors.blue
                                : Colors.black), // Màu cho tin nhắn hình ảnh
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
