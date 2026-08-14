// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

part of 'create_thread_screen.dart';

extension CreateThreadMediaExtensions on _CreateThreadScreenState {
  Future<void> _loadExistingMedia() async {
    final urls = widget.editPost!.imageUrls;
    if (urls == null || urls.isEmpty) return;

    setState(() {
      _isLoadingExistingMedia = true;
    });

    try {
      final List<Uint8List> downloadedBytes = [];
      final HttpClient client = HttpClient();

      for (final url in urls) {
        try {
          final Uri uri = Uri.parse(url);
          final HttpClientRequest request = await client.getUrl(uri);
          final HttpClientResponse response = await request.close();
          if (response.statusCode == 200) {
            final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
            downloadedBytes.add(bytes);
          }
        } catch (e) {
          debugPrint("Failed to download image $url: $e");
        }
      }

      if (mounted && downloadedBytes.isNotEmpty) {
        setState(() {
          _selectedImagesBytesList.addAll(downloadedBytes);
          _originalImagesBytesList.addAll(downloadedBytes);
        });
      }
    } catch (e) {
      debugPrint("Error loading existing media: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingMedia = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isEmpty) return;

      final List<Uint8List> bytesList = [];
      for (var img in images) {
        final bytes = await img.readAsBytes();
        bytesList.add(bytes);
      }

      setState(() {
        _selectedImagesBytesList.addAll(bytesList);
        _originalImagesBytesList.addAll(bytesList);
        _showImageInput = false; // Turn off generic URL input
      });
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _pickCameraImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImagesBytesList.add(bytes);
        _originalImagesBytesList.add(bytes);
        _showImageInput = false;
      });
    } catch (e) {
      debugPrint("Error picking camera image: $e");
    }
  }

  Future<void> _openPhotoEditorAtIndex(int index) async {
    if (index < 0 || index >= _originalImagesBytesList.length) return;
    final originalBytes = _originalImagesBytesList[index];
    
    // Write bytes to temp file to pass to the shared editor
    final dir = await getTemporaryDirectory();
    final tempOriginal = File('${dir.path}/temp_original_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempOriginal.writeAsBytes(originalBytes);

    if (!mounted) return;
    final editedFile = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (context) => SharedPhotoEditorScreen(imageFile: tempOriginal),
      ),
    );

    if (editedFile != null) {
      final editedBytes = await editedFile.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImagesBytesList[index] = editedBytes;
        });
      }
    }
  }

}
