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
  // Cập nhật hàm để nhận BuildContext như một tham số
  Future<List<String>> _getImagesFromFolder(BuildContext context) async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final imagePaths = manifestMap.keys.where((String key) => key.startsWith('assets/images/${widget.folderName}/')).toList();
      return imagePaths;
    } catch (e) {
      print("Error loading images for folder ${widget.folderName}: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              caption: widget.caption,  // Tham chiếu widget.caption
              folderName: widget.folderName,  // Tham chiếu widget.folderName
              customImagePath: widget.customImagePath,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/LibDLU.jpg'),
              ),
              title: Text(
                'Thư viện DLU',
                style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
              child: Text(
                widget.caption,  // Tham chiếu widget.caption
                style: GoogleFonts.openSans(fontSize: 14),
              ),
            ),
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
                future: _getImagesFromFolder(context), // Truyền context vào
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("Không có hình ảnh"));
                  } else {
                    final images = snapshot.data!;
                    return _buildImageCollage(images);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCollage(List<String> images) {
    final double collageWidth = MediaQuery.of(context).size.width - 32;
    const double collageHeight = 200;
    const double gap = 2.0;

    Widget buildImage(String imagePath, {required double width, required double height}) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Center(
              child: Icon(Icons.error, color: Colors.white),
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: collageWidth,
        height: collageHeight,
        color: Colors.white,
        child: images.length == 1
            ? buildImage(images[0], width: collageWidth, height: collageHeight)
            : Row(
                children: [
                  buildImage(images[0], width: (collageWidth - gap) / 2, height: collageHeight),
                  SizedBox(width: gap),
                  buildImage(images[1], width: (collageWidth - gap) / 2, height: collageHeight),
                ],
              ),
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final String caption;
  final String folderName;
  final String? customImagePath;

  const PostDetailPage({
    Key? key,
    required this.caption,
    required this.folderName,
    this.customImagePath,
  }) : super(key: key);

  Future<List<String>> _getImagesFromFolder(BuildContext context, String folderName) async {
    try {
      final manifestContent =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/$folderName/'))
          .toList();
      return imagePaths;
    } catch (e) {
      print("Error loading images for folder $folderName: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('../assets/images/LibDLU.jpg'),
                        ),
                        title: Text(
                          'Thư viện DLU',
                          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
                        child: Text(
                          caption,
                          style: GoogleFonts.openSans(fontSize: 14),
                        ),
                      ),
                      if (customImagePath != null && customImagePath!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    images: [customImagePath!],
                                    initialIndex: 0,
                                    isAsset: false,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              child: Image.file(
                                File(customImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          ),
                        )
                      else if (folderName.isNotEmpty)
                        FutureBuilder<List<String>>(
                          future: _getImagesFromFolder(context, folderName),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text("Không có hình ảnh"));
                            } else {
                              final images = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FullScreenImagePage(
                                              images: images,
                                              initialIndex: index,
                                              isAsset: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        child: Image.asset(
                                          images[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final bool isAsset;

  const FullScreenImagePage({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.isAsset,
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
                  child: isAsset
                      ? Image.asset(
                          images[index],
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(images[index]),
                          fit: BoxFit.contain,
                        ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
