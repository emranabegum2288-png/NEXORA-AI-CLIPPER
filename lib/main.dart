
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFF090914),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController urlController =
      TextEditingController();

  int selectedDuration = 30;
  bool isProcessing = false;

  Future<void> pasteLink() async {
    final data = await Clipboard.getData(
      Clipboard.kTextPlain,
    );

    if (data?.text != null) {
      urlController.text = data!.text!;
    }
  }

  void generateShorts() {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a video link first!'),
        ),
      );
      return;
    }

    if (!url.startsWith('https://') &&
        !url.startsWith('http://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid video URL.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Link received! AI processing will be added next.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF4F46E5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'AI CLIPPER',
                          style: TextStyle(
                            color: Color(0xFFAA8BFA),
                            fontSize: 11,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white70,
                    size: 30,
                  ),
                ],
              ),

              const SizedBox(height: 38),

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
                  color: Color(0xFFAA8BFA),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Create vertical short videos with AI.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF151525),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF37305B),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Color(0xFFAA8BFA),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'YouTube Video Link',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 17),

                    TextField(
                      controller: urlController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste your video URL here...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF090914),
                        suffixIcon: IconButton(
                          onPressed: pasteLink,
                          icon: const Icon(
                            Icons.content_paste,
                            color: Color(0xFFAA8BFA),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'SHORT VIDEO LENGTH',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [15, 30, 60].map((seconds) {
                        final selected =
                            selectedDuration == seconds;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 8,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDuration = seconds;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF7045D8)
                                      : const Color(0xFF222236),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFAA8BFA)
                                        : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${seconds}s',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: generateShorts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF8050E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 10),
                            Text(
                              'GENERATE SHORTS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 17),

              const FeatureTile(
                icon: Icons.video_library_outlined,
                title: 'Add Your Video',
                subtitle: 'Paste a video link to get started.',
              ),

              const FeatureTile(
                icon: Icons.auto_awesome,
                title: 'AI Finds Best Moments',
                subtitle: 'Automatically identify interesting clips.',
              ),

              const FeatureTile(
                icon: Icons.download_rounded,
                title: 'Export Your Shorts',
                subtitle: 'Prepare vertical videos for sharing.',
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'NEXORA AI CLIPPER • VERSION 1.0',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    letterSpacing: 1,
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

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF211B39),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFAA8BFA),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
