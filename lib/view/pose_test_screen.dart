import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pose_detection_service.dart';

class PoseTestScreen extends StatefulWidget {
  const PoseTestScreen({super.key});

  @override
  State<PoseTestScreen> createState() => _PoseTestScreenState();
}

class _PoseTestScreenState extends State<PoseTestScreen> {
  final PoseDetectionService _poseService = PoseDetectionService();
  File? _selectedImage;
  Map<String, dynamic>? _detectionResult;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePoseDetection();
  }

  Future<void> _initializePoseDetection() async {
    setState(() => _isProcessing = true);

    // Initialize with default model settings
    final initialized = await _poseService.initialize(
      numPoses: 1,
      minDetectionConfidence: 0.5,
      minPresenceConfidence: 0.5,
      minTrackingConfidence: 0.5,
    );

    setState(() {
      _isInitialized = initialized;
      _isProcessing = false;
    });

    if (!initialized) {
      _errorMessage = 'Failed to initialize pose detection service';
      _showError(_errorMessage!);
    }
  }

  Future<void> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      _showError('Gallery permission denied');
      return;
    }

    if (status.isPermanentlyDenied) {
      _showError(
        'Gallery permission permanently denied. Please enable it in settings.',
      );
      return;
    }
  }

  Future<void> _pickImage() async {
    if (!_isInitialized) {
      _showError('Pose detection not initialized yet');
      return;
    }

    await _requestGalleryPermission();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectionResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _detectPose() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    if (!_isInitialized) {
      _showError('Pose detection not initialized');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _poseService.detectImage(_selectedImage!.path);

      setState(() {
        _detectionResult = result;
        _isProcessing = false;
        _errorMessage = null;
      });

      if (result == null) {
        _errorMessage =
            'Failed to detect poses in image. Check console for details.';
        _showError(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error detecting pose: $e';
      });
      _showError(_errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDetectionResult(Map<String, dynamic>? result) {
    if (result == null) return 'No data';

    final buffer = StringBuffer();

    result.forEach((key, value) {
      if (value is List) {
        buffer.writeln('$key: [${value.length} items]');
      } else if (value is Map) {
        buffer.writeln('$key: {${value.keys.join(', ')}}');
      } else {
        buffer.writeln('$key: $value');
      }
    });

    return buffer.toString().isEmpty ? 'Empty result' : buffer.toString();
  }

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pose Detection Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isInitialized)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Initializing pose detection...'),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Service Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isInitialized
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isInitialized ? Icons.check_circle : Icons.error,
                    color: _isInitialized ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isInitialized
                        ? 'Pose Detection: Ready'
                        : 'Pose Detection: Not Ready',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image Selection Button
            ElevatedButton.icon(
              onPressed: _isInitialized && !_isProcessing ? _pickImage : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Image Preview
            if (_selectedImage != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),

              // Detect Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _detectPose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Detect Pose',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],

            const SizedBox(height: 24),

            // Error Message Display
            if (_errorMessage != null && _detectionResult == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Detection Results
            if (_detectionResult != null) ...[
              const Text(
                'Detection Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _formatDetectionResult(_detectionResult),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
