import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/widgets/display_message_type.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:translator/translator.dart';

class ContactMessageWidget extends StatefulWidget {
  const ContactMessageWidget({
    super.key,
    required this.message,
    required this.onRightSwipe,
  });

  final MessageModel message;
  final Function() onRightSwipe;

  @override
  State<ContactMessageWidget> createState() => _ContactMessageWidgetState();
}

class _ContactMessageWidgetState extends State<ContactMessageWidget> {
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
    final senderName =
        widget.message.repliedTo == 'Bạn' ? widget.message.senderName : 'Bạn';

    return SwipeTo(
      onRightSwipe: (details) {
        widget.onRightSwipe();
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            minWidth: MediaQuery.of(context).size.width * 0.3,
          ),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: widget.message.messageType == MessageEnum.text
                      ? const EdgeInsets.fromLTRB(10.0, 30.0, 20.0, 20.0)
                      : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isReplying) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DisplayMessageType(
                                  message: widget.message.repliedMessage,
                                  type: widget.message.messageType,
                                  color: Colors.black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      DisplayMessageType(
                        // message: widget.message.message,
                        message: _isTranslate
                            ? _translatedText
                            : widget.message.message,
                        type: widget.message.messageType,
                        color: Colors.black,
                      ),
                      if (widget.message.messageType == MessageEnum.text)
                        GestureDetector(
                          onTap: _translateMessage,
                          child: Text(
                            _isTranslate ? 'Bản gốc' : 'Dịch',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
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
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                        ),
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
