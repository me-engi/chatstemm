import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class ImageWidget extends StatelessWidget {
  final String mediaUrl;

  ImageWidget({required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadImage(context, mediaUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerWidget(width: double.infinity, height: 200);
        } else if (snapshot.hasError) {
          return Text('Error loading image');
        } else {
          return Image.network(mediaUrl);
        }
      },
    );
  }

  Future<void> _loadImage(BuildContext context, String url) async {
    await precacheImage(NetworkImage(url), context);
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String mediaUrl;

  VideoPlayerWidget({required this.mediaUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.mediaUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : ShimmerWidget(width: double.infinity, height: 200);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class PDFViewWidget extends StatefulWidget {
  final String pdfUrl;

  PDFViewWidget({required this.pdfUrl});

  @override
  _PDFViewWidgetState createState() => _PDFViewWidgetState();
}

class _PDFViewWidgetState extends State<PDFViewWidget> {
  bool _isLoading = true;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf(widget.pdfUrl);
  }

  Future<void> _downloadAndSavePdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp.pdf');
        await file.writeAsBytes(bytes, flush: true);
        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? ShimmerWidget(width: double.infinity, height: 400)
        : _localFilePath != null
            ? Container(
                height: 400,
                child: PDFView(
                  filePath: _localFilePath!,
                  onRender: (_) {
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  onError: (error) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error loading PDF: $error")),
                    );
                  },
                ),
              )
            : Center(child: Text('Error displaying PDF'));
  }
}

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;

  ShimmerWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
