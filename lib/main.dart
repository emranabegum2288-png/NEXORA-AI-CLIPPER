
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXORA AI CLIPPER',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B14),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String backendUrl =
      'https://nexora-ai-clipper.onrender.com';

  PlatformFile? selectedVideo;
  String selectedDuration = '60s';
  String status = 'Choose a video to get started';
  String? downloadUrl;

  bool backendConnected = false;
  bool generating = false;

  final List<String> durations = [
    '15s',
    '30s',
    '60s',
    '2 Min',
    '3 Min',
    '4 Min',
    '5 Min',
    '6 Min',
    '7 Min',
    '8 Min',
    '9 Min',
    '10 Min',
  ];

  @override
  void initState() {
    super.initState();
    checkBackend();
  }

  Future<void> checkBackend() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() {
        backendConnected = response.statusCode == 200;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        backendConnected = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null) {
        showMessage('Could not read this video. Please select again.');
        return;
      }

      if (file.size > 50 * 1024 * 1024) {
        showMessage('Video must be smaller than 50 MB.');
        return;
      }

      setState(() {
        selectedVideo = file;
        downloadUrl = null;
        status = 'Video selected successfully';
      });
    } catch (e) {
      showMessage('Video selection failed: $e');
    }
  }

  Future<void> generateShorts() async {
    if (selectedVideo == null || selectedVideo!.bytes == null) {
      showMessage('Please select a video first.');
      return;
    }

    if (!backendConnected) {
      showMessage('Backend is not connected. Please try again.');
      await checkBackend();
      return;
    }

    setState(() {
      generating = true;
      downloadUrl = null;
      status = 'Uploading and processing video...';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/generate'),
      );

      request.fields['duration'] = selectedDuration;

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          selectedVideo!.bytes!,
          filename: selectedVideo!.name,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final path = data['downloadUrl'];

        setState(() {
          downloadUrl = '$backendUrl$path';
          status = 'Video processing completed!';
        });

        showMessage('Your video is ready!');
      } else {
        setState(() {
          status = data['message'] ?? 'Video processing failed.';
        });
        showMessage(status);
      }
    } catch (e) {
      setState(() {
        status = 'Processing failed. Please try again.';
      });
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }

  Future<void> downloadVideo() async {
    if (downloadUrl == null) return;

    await Clipboard.setData(
      ClipboardData(text: downloadUrl!),
    );

    showMessage('Download link copied. Open it in your browser.');
  }

  Widget featureItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurpleAccent),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEXORA AI CLIPPER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF11162A),
        actions: [
          IconButton(
            onPressed: checkBackend,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 15),
              const Icon(
                Icons.movie_creation_outlined,
                size: 65,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Turn Videos Into Shorts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create vertical short videos with NEXORA.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),

              Card(
                color: const Color(0xFF151B30),
                child: ListTile(
                  leading: Icon(
                    backendConnected
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: backendConnected
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  title: const Text('Backend Status'),
                  subtitle: Text(
                    backendConnected
                        ? 'Backend Connected'
                        : 'Backend Disconnected',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: generating ? null : pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('SELECT VIDEO FROM PHONE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                color: const Color(0xFF151B30),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        'SELECTED VIDEO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedVideo?.name ?? 'No video selected',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'SHORT VIDEO LENGTH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durations.map((duration) {
                  final selected = selectedDuration == duration;

                  return ChoiceChip(
                    label: Text(duration),
                    selected: selected,
                    onSelected: generating
                        ? null
                        : (_) {
                            setState(() {
                              selectedDuration = duration;
                            });
                          },
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: generating ? null : generateShorts,
                icon: generating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  generating ? 'PROCESSING...' : 'GENERATE SHORT VIDEO',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(17),
                ),
              ),

              const SizedBox(height: 18),

              Card(
                color: const Color(0xFF151B30),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              if (downloadUrl != null) ...[
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: downloadVideo,
                  icon: const Icon(Icons.download),
                  label: const Text('COPY VIDEO DOWNLOAD LINK'),
                ),
              ],

              const SizedBox(height: 25),

              const Text(
                'FEATURES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              featureItem(
                Icons.video_library,
                'Video Upload',
                'Select a video from your phone.',
              ),

              featureItem(
                Icons.aspect_ratio,
                'Vertical Format',
                'Convert video to 9:16 format.',
              ),

              featureItem(
                Icons.timer,
                'Multiple Durations',
                'Choose from 15 seconds to 10 minutes.',
              ),

              const SizedBox(height: 20),

              const Text(
                'NEXORA AI CLIPPER',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
