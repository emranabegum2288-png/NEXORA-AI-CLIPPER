
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
  final TextEditingController linkController =
      TextEditingController();

  final String backendUrl =
      'https://nexora-ai-clipper.onrender.com';

  int selectedDuration = 1;
  PlatformFile? selectedVideo;

  bool backendConnected = false;
  bool checkingBackend = false;
  bool generating = false;

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
    if (mounted) {
      setState(() => checkingBackend = true);
    }

    try {
      final response = await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        backendConnected =
            response.statusCode == 200 &&
            data['success'] == true;
        checkingBackend = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        backendConnected = false;
        checkingBackend = false;
      });
    }
  }

  Future<void> pasteLink() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      linkController.text = data.text!;
    }
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
          linkController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${selectedVideo!.name}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select video.'),
        ),
      );
    }
  }

  Future<void> generateShorts() async {
    final link = linkController.text.trim();

    if (selectedVideo == null && link.isEmpty) {
      showMessage('Please select a video first!');
      return;
    }

    if (selectedVideo == null &&
        !link.contains('youtube.com') &&
        !link.contains('youtu.be')) {
      showMessage('Please enter a valid YouTube link!');
      return;
    }

    if (!backendConnected) {
      await checkBackend();
    }

    if (!mounted) return;

    if (!backendConnected) {
      showMessage('Backend connection failed!');
      return;
    }

    setState(() => generating = true);

    try {
      // AI processing endpoint is not implemented yet.
      final response = await http
          .post(
            Uri.parse('$backendUrl/generate'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'duration': durations[selectedDuration],
              'source': selectedVideo != null
                  ? 'uploaded_video'
                  : 'youtube_link',
              'filename': selectedVideo?.name,
              'video_url': link.isEmpty ? null : link,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 501) {
        showMessage(
          'Backend connected! AI video processing is not implemented yet.',
        );
      } else if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        showMessage('Request submitted successfully!');
      } else {
        showMessage(data['message'] ?? 'Something went wrong.');
      }
    } catch (e) {
      if (mounted) {
        showMessage('Connection error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => generating = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget durationButton(int index) {
    final isSelected = selectedDuration == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedDuration = index);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7545E8)
              : const Color(0xFF242337),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB18AFF)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          durations[index],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF211B3B),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFAD85FF),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
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
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9655F8),
                          Color(0xFF553CE8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.movie_filter,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'A I   C L I P P E R',
                          style: TextStyle(
                            color: Color(0xFFAD85FF),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 35,
                  ),
                ],
              ),

              const SizedBox(height: 35),

              Row(
                children: [
                  Icon(
                    checkingBackend
                        ? Icons.sync
                        : backendConnected
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                    color: checkingBackend
                        ? Colors.orange
                        : backendConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    checkingBackend
                        ? 'Checking Backend...'
                        : backendConnected
                            ? 'Backend Connected'
                            : 'Backend Disconnected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: checkBackend,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Turn Long Videos',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Into Viral Shorts.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA83FF),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Create vertical short videos with AI.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF171625),
                  borderRadius: BorderRadius.circular(28),
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
                        SizedBox(width: 12),
                        Text(
                          'Choose Your Video',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text(
                          'SELECT VIDEO FROM PHONE',
                        ),
                      ),
                    ),

                    if (selectedVideo != null) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Selected: ${selectedVideo!.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 25),

                    const Center(
                      child: Text(
                        'OR PASTE A YOUTUBE LINK',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: linkController,
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            selectedVideo != null) {
                          setState(() => selectedVideo = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Paste your video URL here...',
                        filled: true,
                        fillColor: const Color(0xFF090914),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: pasteLink,
                          icon: const Icon(Icons.content_paste),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'SHORT VIDEO LENGTH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 20),

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
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        return durationButton(index);
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed:
                            generating ? null : generateShorts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF814CEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
                                  SizedBox(width: 12),
                                  Text(
                                    'GENERATE SHORTS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 45),

              const Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 25),

              featureItem(
                Icons.video_library_outlined,
                'Add Your Video',
                'Select a video from your phone.',
              ),

              featureItem(
                Icons.auto_awesome,
                'AI Finds Best Moments',
                'AI processing will be added next.',
              ),

              featureItem(
                Icons.download,
                'Export Your Shorts',
                'Download generated videos when available.',
              ),

              const SizedBox(height: 35),

              const Center(
                child: Text(
                  'NEXORA AI CLIPPER • VERSION 1.0',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
