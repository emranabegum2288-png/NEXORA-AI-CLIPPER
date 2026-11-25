
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090914),
        fontFamily: 'Roboto',
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

  int selectedDuration = 1;
  bool isGenerating = false;

  final List<String> durations = [
    '15s',
    '30s',
    '60s',
    '2 Min',
    '5 Min',
    '10 Min',
  ];

  Future<void> pasteLink() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      linkController.text = data.text!;
    }
  }

  void generateShorts() {
    final link = linkController.text.trim();

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a video link first!'),
        ),
      );
      return;
    }

    if (!link.contains('youtube.com') &&
        !link.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid YouTube link!'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected duration: ${durations[selectedDuration]}. '
          'AI video processing is not connected yet.',
        ),
      ),
    );
  }

  Widget durationButton(int index) {
    final isSelected = selectedDuration == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDuration = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          vertical: 23,
          horizontal: 5,
        ),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF211B3B),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFAD85FF),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8E4EF),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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

              // HEADER

              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9655F8),
                          Color(0xFF553CE8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.movie_filter,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'A I   C L I P P E R',
                          style: TextStyle(
                            color: Color(0xFFAD85FF),
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 38,
                    color: Colors.white70,
                  ),
                ],
              ),

              const SizedBox(height: 65),

              // MAIN TITLE

              const Text(
                'Turn Long Videos',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEAE6F0),
                ),
              ),

              const Text(
                'Into Viral Shorts.',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA83FF),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Create vertical short videos with AI.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 48),

              // VIDEO INPUT CARD

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF171625),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF403263),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Color(0xFFAA83FF),
                          size: 28,
                        ),
                        SizedBox(width: 14),
                        Text(
                          'YouTube Video Link',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // LINK FIELD

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF090914),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: linkController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Paste your video URL here...',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 22,
                          ),
                          suffixIcon: IconButton(
                            onPressed: pasteLink,
                            icon: const Icon(
                              Icons.content_paste,
                              color: Color(0xFFAA83FF),
                              size: 29,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

                    const Text(
                      'SHORT VIDEO LENGTH',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white60,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DURATION BUTTONS

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

                    const SizedBox(height: 35),

                    // GENERATE BUTTON

                    SizedBox(
                      width: double.infinity,
                      height: 78,
                      child: ElevatedButton(
                        onPressed: generateShorts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF814CEB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(22),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 25,
                            ),
                            SizedBox(width: 15),
                            Text(
                              'GENERATE SHORTS',
                              style: TextStyle(
                                fontSize: 17,
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

              const SizedBox(height: 50),

              // HOW IT WORKS

              const Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 28),

              featureItem(
                Icons.video_library_outlined,
                'Add Your Video',
                'Paste a video link to get started.',
              ),

              featureItem(
                Icons.auto_awesome,
                'AI Finds Best Moments',
                'Automatically identify interesting clips.',
              ),

              featureItem(
                Icons.download,
                'Export Your Shorts',
                'Prepare vertical videos for sharing.',
              ),

              const SizedBox(height: 45),

              const Center(
                child: Text(
                  'NEXORA AI CLIPPER • VERSION 1.0',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}
