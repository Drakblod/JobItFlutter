import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/drawing/annotation.dart';
import '../../services/theme_localization_service.dart';

enum EditorTool { arrow, circle, text }

class DrawingCanvas extends StatefulWidget {
  final String imagePath; // Can be a local file path or network URL
  final ui.Image bgImage;
  final Function(List<Annotation>) onAnnotationsChanged;

  const DrawingCanvas({
    super.key,
    required this.imagePath,
    required this.bgImage,
    required this.onAnnotationsChanged,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<Annotation> _annotations = [];
  Annotation? _currentAnnotation;
  Offset? _startPoint;
  
  EditorTool _currentTool = EditorTool.arrow;
  Color _currentColor = Colors.red;

  List<Annotation> get annotations => _annotations;
  EditorTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;

  void selectTool(EditorTool tool) {
    setState(() {
      _currentTool = tool;
    });
  }

  void changeColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  void undo() {
    if (_annotations.isNotEmpty) {
      setState(() {
        _annotations.removeLast();
      });
      widget.onAnnotationsChanged(_annotations);
    }
  }

  void clear() {
    setState(() {
      _annotations.clear();
      _currentAnnotation = null;
    });
    widget.onAnnotationsChanged(_annotations);
  }

  // Exports the drawing merged with the background image as PNG bytes!
  Future<Uint8List?> exportAnnotatedImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final bgW = widget.bgImage.width.toDouble();
    final bgH = widget.bgImage.height.toDouble();
    final imageSize = Size(bgW, bgH);

    // 1. Draw Background Image
    canvas.drawImage(widget.bgImage, Offset.zero, Paint());

    // 2. We need to scale our annotations from the local view coordinates to the original image dimensions!
    // Get the canvas size from the view
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final viewSize = renderBox.size;

    // Calculate aspect fit coordinates
    final double imageAspect = bgW / bgH;
    final double viewAspect = viewSize.width / viewSize.height;

    double scale, dx = 0, dy = 0;
    if (imageAspect > viewAspect) {
      scale = bgW / viewSize.width;
      dy = (viewSize.height * scale - bgH) / 2;
    } else {
      scale = bgH / viewSize.height;
      dx = (viewSize.width * scale - bgW) / 2;
    }

    // Apply scale and translation transformation to coordinates
    canvas.save();
    canvas.translate(-dx, -dy);
    canvas.scale(scale);

    for (var ann in _annotations) {
      ann.draw(canvas, viewSize);
    }
    
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(bgW.toInt(), bgH.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  double _getDistance(Offset p1, Offset p2) {
    return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
  }

  Future<void> _showTextPrompt(Offset position) async {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
    final textController = TextEditingController();

    final String? text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: provider.backgroundColor,
        title: const Text('Add Text Annotation', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text here',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _annotations.add(TextAnnotation(
          position: position,
          text: text.trim(),
          color: _currentColor,
        ));
      });
      widget.onAnnotationsChanged(_annotations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _startPoint = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        if (_startPoint == null) return;
        final endPoint = details.localPosition;

        setState(() {
          switch (_currentTool) {
            case EditorTool.arrow:
              _currentAnnotation = LineAnnotation(
                start: _startPoint!,
                end: endPoint,
                isArrow: true,
                color: _currentColor,
              );
              break;
            case EditorTool.circle:
              final radius = _getDistance(_startPoint!, endPoint);
              _currentAnnotation = CircleAnnotation(
                center: _startPoint!,
                radius: radius,
                color: _currentColor,
              );
              break;
            case EditorTool.text:
              // Draw dot preview
              _currentAnnotation = CircleAnnotation(
                center: endPoint,
                radius: 3.0,
                color: _currentColor,
              );
              break;
          }
        });
      },
      onPanEnd: (details) {
        if (_startPoint == null) return;
        final Offset endPoint = _currentAnnotation is LineAnnotation 
            ? (_currentAnnotation as LineAnnotation).end 
            : (_currentAnnotation is CircleAnnotation 
                ? (_currentAnnotation as CircleAnnotation).center 
                : _startPoint!);

        if (_currentTool == EditorTool.text) {
          _showTextPrompt(endPoint);
        } else if (_currentAnnotation != null) {
          setState(() {
            _annotations.add(_currentAnnotation!);
          });
          widget.onAnnotationsChanged(_annotations);
        }

        setState(() {
          _startPoint = null;
          _currentAnnotation = null;
        });
      },
      child: CustomPaint(
        painter: CanvasPainter(
          bgImage: widget.bgImage,
          annotations: _annotations,
          currentAnnotation: _currentAnnotation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final ui.Image bgImage;
  final List<Annotation> annotations;
  final Annotation? currentAnnotation;

  CanvasPainter({
    required this.bgImage,
    required this.annotations,
    this.currentAnnotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Aspect Fit Image
    final double imgW = bgImage.width.toDouble();
    final double imgH = bgImage.height.toDouble();
    final double canvasW = size.width;
    final double canvasH = size.height;

    final double imgAspect = imgW / imgH;
    final double canvasAspect = canvasW / canvasH;

    double drawW, drawH, x, y;
    if (imgAspect > canvasAspect) {
      drawW = canvasW;
      drawH = drawW / imgAspect;
      x = 0;
      y = (canvasH - drawH) / 2;
    } else {
      drawH = canvasH;
      drawW = drawH * imgAspect;
      y = 0;
      x = (canvasW - drawW) / 2;
    }

    final src = Rect.fromLTWH(0, 0, imgW, imgH);
    final dst = Rect.fromLTWH(x, y, drawW, drawH);
    canvas.drawImageRect(bgImage, src, dst, Paint());

    // 2. Draw Annotations
    for (var ann in annotations) {
      ann.draw(canvas, size);
    }

    // 3. Draw Active Preview
    if (currentAnnotation != null) {
      currentAnnotation!.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}
