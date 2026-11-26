
Future<void> generateShorts() async {
  if (selectedVideo == null) {
    showMessage(
      'Please select a video from your phone. YouTube links are not supported yet.',
    );
    return;
  }

  final videoBytes = selectedVideo!.bytes;

  if (videoBytes == null || videoBytes.isEmpty) {
    showMessage('Could not read video. Please select it again.');
    return;
  }

  if (videoBytes.length > 50 * 1024 * 1024) {
    showMessage('Video must be smaller than 50 MB.');
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendUrl/generate'),
    );

    request.fields['duration'] = durations[selectedDuration];

    request.files.add(
      http.MultipartFile.fromBytes(
        'video',
        videoBytes,
        filename: selectedVideo!.name,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 5),
    );

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (!mounted) return;

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      final downloadUrl =
          '$backendUrl${data['downloadUrl']}';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Video Processing Complete'),
          content: SelectableText(
            'Your video is ready!\n\n$downloadUrl',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: downloadUrl),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  showMessage('Download link copied!');
                }
              },
              child: const Text('COPY DOWNLOAD LINK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
    } else {
      showMessage(
        data['message'] ?? 'Video processing failed.',
      );
    }
  } catch (e) {
    if (mounted) {
      showMessage('Upload or processing failed. Try again.');
    }
  } finally {
    if (mounted) {
      setState(() => generating = false);
    }
  }
}
