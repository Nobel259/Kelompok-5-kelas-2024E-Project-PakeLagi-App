import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CropperPage extends StatefulWidget {
  final File imageFile;
  final bool isCircular;

  const CropperPage({
    super.key,
    required this.imageFile,
    this.isCircular = false,
  });

  @override
  State<CropperPage> createState() => _CropperPageState();
}

class _CropperPageState extends State<CropperPage> {
  final GlobalKey _cropperKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _cropImage() async {
    setState(() => _isProcessing = true);
    try {
      final boundary =
          _cropperKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(buffer);

      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memotong gambar',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cropWidth = size.width;
    final cropHeight = widget.isCircular ? cropWidth : cropWidth * 4 / 3;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Atur Posisi',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _cropImage,
                ),
        ],
      ),
      body: Stack(
        children: [
          // Background instructions
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                'Geser dan cubit untuk menyesuaikan gambar',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
          Center(
            child: ClipRect(
              child: RepaintBoundary(
                key: _cropperKey,
                child: Container(
                  width: cropWidth,
                  height: cropHeight,
                  decoration: widget.isCircular
                      ? const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        )
                      : const BoxDecoration(color: Colors.black),
                  clipBehavior: Clip.hardEdge,
                  child: InteractiveViewer(
                    minScale: 0.1,
                    maxScale: 4.0,
                    boundaryMargin: EdgeInsets.symmetric(
                      horizontal: cropWidth,
                      vertical: cropHeight,
                    ),
                    child: Image.file(widget.imageFile, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          // Overlay for circular crop preview
          if (widget.isCircular)
            IgnorePointer(
              child: Center(
                child: Container(
                  width: cropWidth,
                  height: cropHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            )
          else
            IgnorePointer(
              child: Center(
                child: Container(
                  width: cropWidth,
                  height: cropHeight,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
