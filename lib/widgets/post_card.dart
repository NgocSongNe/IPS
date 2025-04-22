import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';

class PostCard extends StatefulWidget {
  final String caption;
  final String folderName;
  final String? customImagePath;

  const PostCard({
    Key? key,
    required this.caption,
    required this.folderName,
    this.customImagePath,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Future<List<String>> _getImagesFromFolder(BuildContext context) async {
    try {
      final manifestContent =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/${widget.folderName}/'))
          .toList();
      return imagePaths;
    } catch (e) {
      print("Error loading images for folder ${widget.folderName}: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.caption.split('-').first.trim();
    String content = widget.caption.length > 100
        ? '${widget.caption.substring(0, 100)}...'
        : widget.caption;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              caption: widget.caption,
              folderName: widget.folderName,
              customImagePath: widget.customImagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.customImagePath != null && widget.customImagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Image.file(
                    File(widget.customImagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              )
            else if (widget.folderName.isNotEmpty)
              FutureBuilder<List<String>>(
                future: _getImagesFromFolder(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade600,
                          size: 50,
                        ),
                      ),
                    );
                  } else {
                    final images = snapshot.data!;
                    return Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                images[index],
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    color: Colors.grey.shade300,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey.shade600,
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xem thêm',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.teal.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostDetailPage extends StatefulWidget {
  final String caption;
  final String folderName;
  final String? customImagePath;

  const PostDetailPage({
    Key? key,
    required this.caption,
    required this.folderName,
    this.customImagePath,
  }) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<String> images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    if (widget.customImagePath != null) {
      setState(() {
        images = [widget.customImagePath!];
      });
    } else {
      try {
        final manifestContent =
            await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        final imagePaths = manifestMap.keys
            .where((String key) => key.startsWith('assets/images/${widget.folderName}/'))
            .toList();
        setState(() {
          images = imagePaths;
        });
      } catch (e) {
        print("Error loading images for folder ${widget.folderName}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.caption.split('-').first.trim();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AppBar tùy chỉnh
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade600, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.openSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Icon(
                              Icons.info,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Tên địa điểm
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          title,
                          style: GoogleFonts.openSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Caption
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          widget.caption,
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Hình ảnh (xếp thành cột)
                      if (images.isNotEmpty)
                        Column(
                          children: images.asMap().entries.map((entry) {
                            int index = entry.key;
                            String image = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImagePage(
                                        images: images,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    image,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey.shade300,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey.shade600,
                                            size: 50,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // Nút quay lại
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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

class FullScreenImagePage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImagePage({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return Center(
                  child: Image.asset(
                    images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade600,
                          size: 50,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}