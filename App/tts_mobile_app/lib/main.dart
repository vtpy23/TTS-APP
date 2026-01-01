import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F5-TTS Vietnamese - Nhóm 19',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const TTSPage(),
    );
  }
}

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State createState() => _TTSPageState();
}

class _TTSPageState extends State {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  String _statusMessage = '';
  double _speed = 1.0;
  bool _removeSilence = true;

  // ⚠️ THAY URL NGROK CỦA BẠN Ở ĐÂY
  final String serverUrl =
      "https://bryson-magnoliaceous-ebony.ngrok-free.dev/tts";

  @override
  void initState() {
    super.initState();
    _textController.text =
        "Xin chào thầy cô và các bạn. Đây là đồ án Text-to-Speech "
        "sử dụng mô hình F5-TTS Vietnamese của nhóm 19.";
  }

  Future _generateSpeech() async {
    if (_textController.text.trim().isEmpty) {
      _showMessage('⚠️ Vui lòng nhập văn bản!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Đang xử lý với F5-TTS...';
    });

    try {
      // Gửi request đến server
      final response = await http
          .post(
            Uri.parse(serverUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": _textController.text.trim(),
              "speed": _speed,
              "remove_silence": _removeSilence,
            }),
          )
          .timeout(
            const Duration(seconds: 180), // F5-TTS cần thời gian xử lý lâu hơn
            onTimeout: () {
              throw Exception('⏱️ Timeout: Server không phản hồi (>180s)');
            },
          );

      if (response.statusCode == 200) {
        setState(() => _statusMessage = '🎵 Đang phát audio...');

        // Lưu file audio
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/f5tts_$timestamp.wav');
        await file.writeAsBytes(response.bodyBytes);

        // Phát audio
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(file.path));

        setState(() => _statusMessage = '▶️ Đang phát...');

        // Lắng nghe khi audio kết thúc
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() => _statusMessage = '✅ Hoàn thành!');
        });
      } else {
        _showMessage('❌ Lỗi server: ${response.statusCode}');
      }
    } on SocketException {
      _showMessage('❌ Không thể kết nối server. Kiểm tra URL và mạng!');
    } on http.ClientException {
      _showMessage('❌ Lỗi gửi request đến server.');
    } catch (e) {
      _showMessage('❌ Lỗi: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    setState(() => _statusMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future _stopAudio() async {
    await _audioPlayer.stop();
    setState(() => _statusMessage = '⏹️ Đã dừng');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F5-TTS Vietnamese Demo'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.graphic_eq, size: 60, color: Colors.deepPurple),
                    SizedBox(height: 10),
                    Text(
                      'F5-TTS Vietnamese V2',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'High-Quality Text-to-Speech',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Text Input
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '📝 Văn bản tiếng Việt',
                hintText: 'Nhập câu bạn muốn nghe...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),

            const SizedBox(height: 20),

            // Speed Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tốc độ: ${_speed.toStringAsFixed(1)}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${_speed.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() => _speed = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Remove Silence Checkbox
            Card(
              child: CheckboxListTile(
                title: const Text('🔇 Xóa khoảng lặng'),
                subtitle: const Text('Loại bỏ khoảng trống trong audio'),
                value: _removeSilence,
                onChanged: (value) {
                  setState(() => _removeSilence = value ?? true);
                },
                secondary: const Icon(Icons.auto_fix_high),
              ),
            ),

            const SizedBox(height: 20),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateSpeech,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_circle_filled),
                    label: Text(
                      _isLoading ? 'Đang xử lý...' : '🎤 Tạo giọng nói',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _stopAudio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.stop),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Info Footer
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Thông tin mô hình',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Model: F5-TTS Vietnamese V2\n'
                    '• Source: Hugging Face (coutMinh)\n'
                    '• Đồ án cuối kỳ - Nhóm 19',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lưu ý: Quá trình xử lý có thể mất 10-30 giây tùy độ dài văn bản',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
