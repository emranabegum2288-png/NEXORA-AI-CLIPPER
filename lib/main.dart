
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090914),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF814CEB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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

  final TextEditingController linkController =
      TextEditingController();

  PlatformFile? selectedVideo;

  bool backendConnected = false;
  bool checkingBackend = false;
  bool generating = false;

  int selectedDuration = 1;
  String statusMessage = 'Ready to create your video';

  String? downloadUrl;

  final List<String> durations = [
    '15s',
    '30s',
    '60s',
    '2 Min',
    '5 Min',
    '10 Min',
  ];

  @override
  void initState() {
    super.initState();
    checkBackend();
  }

  Future<void> checkBackend() async {
    setState(() => checkingBackend = true);

    try {
      final response = await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 40));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        backendConnected =
            response.statusCode == 200 &&
            data['success'] == true;
        checkingBackend = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        backendConnected = false;
        checkingBackend = false;
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
        allowMultiple: false,
        withData: true,
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedVideo = result.files.first;
          downloadUrl = null;
          statusMessage = 'Video selected successfully';
        });

        showMessage('Video selected!');
      }
    } catch (_) {
      showMessage('Could not select video.');
    }
  }

  Future<void> pasteLink() async {
    final data = await Clipboard.getData('text/plain');

    if (data?.text != null) {
      linkController.text = data!.text!;
      showMessage('Link pasted');
    }
  }

  Future<void> generateShorts() async {
    if (selectedVideo == null) {
      showMessage(
        'Please select a video from your phone. '
        'YouTube links are not supported yet.',
      );
      return;
    }

    final bytes = selectedVideo!.bytes;

    if (bytes == null || bytes.isEmpty) {
      showMessage('Please select the video again.');
      return;
    }

    if (bytes.length > 50 * 1024 * 1024) {
      showMessage('Maximum video size is 50 MB.');
      return;
    }

    if (!backendConnected) {
      await checkBackend();
    }

    if (!mounted) return;

    if (!backendConnected) {
      showMessage('Backend is not connected.');
      return;
    }

    setState(() {
      generating = true;
      downloadUrl = null;
      statusMessage = 'Uploading video...';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/generate'),
      );

      request.fields['duration'] =
          durations[selectedDuration];

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: selectedVideo!.name,
        ),
      );

      if (mounted) {
        setState(() {
          statusMessage = 'Processing video...';
        });
      }

      final streamed = await request.send().timeout(
        const Duration(minutes: 10),
      );

      final response = await http.Response.fromStream(
        streamed,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        final path = data['downloadUrl']?.toString();

        if (path == null || path.isEmpty) {
          throw Exception('Download link missing');
        }

        final url = Uri.parse(backendUrl)
            .resolve(path)
            .toString();

        setState(() {
          downloadUrl = url;
          statusMessage = 'Video processing completed!';
        });

        showMessage('Your video is ready!');
      } else {
        setState(() {
          statusMessage = 'Processing failed';
        });

        showMessage(
          data['message']?.toString() ??
              'Video processing failed.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = 'Something went wrong';
        });

        showMessage(
          'Upload or processing failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => generating = false);
      }
    }
  }

  Widget durationButton(int index) {
    final selected = selectedDuration == index;

    return InkWell(
      onTap: generating
          ? null
          : () {
              setState(() {
                selectedDuration = index;
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7545E8)
              : const Color(0xFF242337),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFB18AFF)
                : Colors.transparent,
          ),
        ),
        child: Text(
          durations[index],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget featureItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF211B3B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFAD85FF),
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9655F8),
                          Color(0xFF553CE8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.movie_filter,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'AI CLIPPER',
                          style: TextStyle(
                            color: Color(0xFFAD85FF),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 32,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Icon(
                    backendConnected
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: backendConnected
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      checkingBackend
                          ? 'Checking Backend...'
                          : backendConnected
                              ? 'Backend Connected'
                              : 'Backend Disconnected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        checkingBackend ? null : checkBackend,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Turn Long Videos',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Into Viral Shorts.',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA83FF),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Create vertical videos with NEXORA.',
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF171625),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF403263),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          color: Color(0xFFAA83FF),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Choose Your Video',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton.icon(
                        onPressed:
                            generating ? null : pickVideo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text(
                          'SELECT VIDEO FROM PHONE',
                        ),
                      ),
                    ),

                    if (selectedVideo != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Selected: ${selectedVideo!.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Size: ${(selectedVideo!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    const Center(
                      child: Text(
                        'OR PASTE A YOUTUBE LINK',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        hintText: 'Paste video URL here...',
                        filled: true,
                        fillColor: const Color(0xFF090914),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: pasteLink,
                          icon: const Icon(Icons.content_paste),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'SHORT VIDEO LENGTH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: durations.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) =>
                          durationButton(index),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed:
                            generating ? null : generateShorts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF814CEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        child: generating
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome),
                                  SizedBox(width: 10),
                                  Text(
                                    'GENERATE SHORTS',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    if (downloadUrl != null) ...[
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: downloadUrl!,
                              ),
                            );
                            showMessage(
                              'Download link copied!',
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text(
                            'COPY VIDEO DOWNLOAD LINK',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 38),

              const Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 22),

              featureItem(
                Icons.video_library_outlined,
                'Add Your Video',
                'Select your own video from your phone.',
              ),

              featureItem(
                Icons.auto_awesome,
                'Video Processing',
                'Create a vertical short vi
