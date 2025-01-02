import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechDialog extends StatefulWidget {
  final TextEditingController _textContentController;

  const SpeechDialog({
    super.key,
    required TextEditingController textContentController,
  }) : _textContentController = textContentController;

  @override
  State<SpeechDialog> createState() => _SpeechDialogState();
  // Hàm tĩnh mở hộp thoại này
  static void show(
    BuildContext context,
    TextEditingController textContentController,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SpeechDialog(
          textContentController: textContentController,
        ),
      ),
    );
  }
}

class _SpeechDialogState extends State<SpeechDialog> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    super.dispose();
    _speechToText.stop();
    _speechToText.cancel();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lastWords = result.recognizedWords;
    });
    // Cập nhật _textContentController khi có kết quả và không còn đang nghe
    if (_lastWords.isNotEmpty && _speechToText.isNotListening) {
      widget._textContentController.text =
          '${widget._textContentController.text} $_lastWords';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Chuyển đổi giọng nói',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            _speechToText.isListening
                ? _lastWords
                : _speechEnabled
                    ? 'Ấn vào micro để bắt đầu lắng nghe...'
                    : 'Speech không được phép',
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed:
                _speechToText.isNotListening ? _startListening : _stopListening,
            icon:
                Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
            label: Text(_speechToText.isNotListening ? "Bắt đầu" : "Dừng"),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
