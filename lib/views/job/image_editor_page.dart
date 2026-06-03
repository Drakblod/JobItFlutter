import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_image.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/glass_card.dart';

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();
  final _storageService = StorageService();
  final _jobService = JobService();

  bool _isLoading = true;
  bool _isSaving = false;
  ui.Image? _bgImage;
  String? _imagePath;
  String? _jobId;
  String? _errorMessage;

  EditorTool _activeTool = EditorTool.arrow;
  Color _activeColor = Colors.red;

  final List<Color> _colorPalette = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.white,
    Colors.orange,
    Colors.purple,
    Colors.black,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bgImage == null && _errorMessage == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _jobId = args['JobId'];
      _imagePath = args['ImagePath'];
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      if (_imagePath == null) throw Exception("No image path provided");

      ImageProvider provider;
      if (_imagePath!.startsWith('http://') || _imagePath!.startsWith('https://')) {
        provider = NetworkImage(_imagePath!);
      } else {
        provider = FileImage(File(_imagePath!));
      }

      final image = await _loadImageProvider(provider);
      setState(() {
        _bgImage = image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<ui.Image> _loadImageProvider(ImageProvider provider) {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo frame, bool synchronousCall) {
        completer.complete(frame.image);
        stream.removeListener(listener);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void _selectTool(EditorTool tool) {
    setState(() {
      _activeTool = tool;
    });
    _canvasKey.currentState?.selectTool(tool);
  }

  void _selectColor(Color color) {
    setState(() {
      _activeColor = color;
    });
    _canvasKey.currentState?.changeColor(color);
  }

  Future<void> _save() async {
    if (_canvasKey.currentState == null || _jobId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final bytes = await _canvasKey.currentState!.exportAnnotatedImage();
      if (bytes == null) {
        throw Exception("Failed to generate annotated image bytes");
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final userName = authService.currentUser?.displayName ?? 'Worker';

      final fileName = '${_jobId}_annotated_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Upload bytes
      final downloadUrl = await _storageService.uploadImage(bytes, fileName);

      // Create new JobImage entry
      final jobImage = JobImage(
        id: '', // Will be pushed
        jobId: _jobId!,
        url: downloadUrl,
        uploadedBy: userName,
        uploadedAt: DateTime.now(),
      );

      await _jobService.addJobImage(_jobId!, jobImage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ImageUploadedSuccess'))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('UploadImageError')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('AnnotatePhotoTitle'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading image:',
                        style: TextStyle(color: themeProvider.textPrimaryColor),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _loadImage();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Canvas Viewport
                    Positioned.fill(
                      bottom: 180, // Leave room for floating controls
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: ClipRect(
                          child: DrawingCanvas(
                            key: _canvasKey,
                            imagePath: _imagePath!,
                            bgImage: _bgImage!,
                            onAnnotationsChanged: (annotations) {
                              // Trigger state updates if needed
                            },
                          ),
                        ),
                      ),
                    ),

                    // Controls panel (bottom overlay)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tool Options & Colors row
                            GlassCard(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 16,
                              child: Column(
                                children: [
                                  // Tools Selection Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildToolButton(
                                        tool: EditorTool.arrow,
                                        icon: Icons.arrow_right_alt,
                                        label: context.tr('ArrowTool'),
                                        themeProvider: themeProvider,
                                      ),
                                      _buildToolButton(
                                        tool: EditorTool.circle,
                                        icon: Icons.radio_button_unchecked,
                                        label: context.tr('CircleTool'),
                                        themeProvider: themeProvider,
                                      ),
                                      _buildToolButton(
                                        tool: EditorTool.text,
                                        icon: Icons.title,
                                        label: context.tr('TextTool'),
                                        themeProvider: themeProvider,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white24, height: 1),
                                  const SizedBox(height: 12),
                                  
                                  // Color Selection Row
                                  SizedBox(
                                    height: 36,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _colorPalette.length,
                                      itemBuilder: (context, index) {
                                        final color = _colorPalette[index];
                                        final isSelected = _activeColor == color;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                          child: GestureDetector(
                                            onTap: () => _selectColor(color),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                                                  width: 3,
                                                ),
                                                boxShadow: [
                                                  if (isSelected)
                                                    BoxShadow(
                                                      color: Colors.cyanAccent.withOpacity(0.5),
                                                      blurRadius: 6,
                                                      spreadRadius: 1,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Undo, Clear, Save actions row
                            Row(
                              children: [
                                // Undo Action
                                Expanded(
                                  child: GlassCard(
                                    padding: EdgeInsets.zero,
                                    borderRadius: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.undo, color: Colors.white),
                                      tooltip: context.tr('Undo'),
                                      onPressed: () => _canvasKey.currentState?.undo(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Clear Action
                                Expanded(
                                  child: GlassCard(
                                    padding: EdgeInsets.zero,
                                    borderRadius: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                                      tooltip: context.tr('Clear'),
                                      onPressed: () => _canvasKey.currentState?.clear(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Save Action
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      context.tr('Save'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Saving blocking overlay
                    if (_isSaving)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Saving Annotations...',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildToolButton({
    required EditorTool tool,
    required IconData icon,
    required String label,
    required ThemeAndLocalizationProvider themeProvider,
  }) {
    final isSelected = _activeTool == tool;
    final color = isSelected ? themeProvider.primaryColor : Colors.white60;

    return InkWell(
      onTap: () => _selectTool(tool),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeProvider.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeProvider.primaryColor.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
