import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_drawer.dart';
import '../widgets/branded_app_bar.dart';

class ReportFaultScreen extends StatefulWidget {
  const ReportFaultScreen({super.key});

  @override
  State<ReportFaultScreen> createState() => _ReportFaultScreenState();
}

class _ReportFaultScreenState extends State<ReportFaultScreen> {
  final _supabase = Supabase.instance.client;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // --- EDGE-PROOF STATE ---
  Uint8List? _imageBytes; // Stores image in memory (works on Edge & Mobile)
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  /// Function to show selection menu
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF1A237E),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            // Camera is usually disabled in desktop browsers but works on mobile Edge
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Picker logic that avoids "File Path" crashes
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality:
            70, // Lower quality prevents Edge from running out of memory
      );

      if (image != null) {
        // Read as bytes immediately to avoid path errors
        final bytes = await image.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      debugPrint("Edge Picker Error: $e");
    }
  }

  /// Upload logic using 'uploadBinary' for cross-platform support
  Future<String?> _uploadImage(String userId) async {
    if (_imageBytes == null) return null;

    try {
      final fileName = 'fault_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';

      // Use uploadBinary – this is the "secret sauce" for Edge/Web
      await _supabase.storage
          .from('fault-images')
          .uploadBinary(
            path,
            _imageBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          )
          .timeout(const Duration(seconds: 30));

      return _supabase.storage.from('fault-images').getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (_locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final imageUrl = await _uploadImage(userId);

      await _supabase.from('faults').insert({
        'reporter_id': userId,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'photo_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fault Reported Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/resident_history');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF1A237E);

    return Scaffold(
      appBar: BrandedAppBar(
        screenName: "New Fault Report",
        backgroundColor: Colors.yellow[700],
        // --- ADDED BACK BUTTON ---
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Location",
                prefixIcon: const Icon(Icons.pin_drop, color: themeBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description of issue",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // --- IMAGE PREVIEW SECTION ---
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _imageBytes == null
                  ? InkWell(
                      onTap: _showPickerOptions,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_enhance_outlined,
                            size: 50,
                            color: themeBlue,
                          ),
                          Text(
                            "Add a photo (Camera or Gallery)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Use Image.memory instead of Image.file for Edge compatibility
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _imageBytes = null),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SUBMIT REPORT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
