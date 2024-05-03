import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'fullScreen_image.dart';


class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final List<Map<String, dynamic>> _images = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  bool _canLoadMore = true;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadImages();
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    if (!_canLoadMore) return;

    setState(() {
      _loading = true;
    });

    final response = await http.get(Uri.parse(
        'https://pixabay.com/api/?key=43678432-87219db883cfe9e2c19a1db96&q=${_searchController.text}&per_page=20&page=$_page'));

    if (response.statusCode == 200) {
      setState(() {
        final List<Map<String, dynamic>> newImages =
        json.decode(response.body)['hits'].cast<Map<String, dynamic>>();
        _images.addAll(newImages);
        if (newImages.length < 20) {
          _canLoadMore = false;
        }
        _loading = false;
        _page++;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  void _onSearchTextChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _images.clear();
        _page = 1;
        _canLoadMore = true;
      });
      _loadImages();
    });
  }

  Timer? _debounce;

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        _canLoadMore) {
      _loadImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search for images...',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth > 1200
                ? 5
                : screenWidth > 1000
                ? 4
                : screenWidth > 600
                ? 3
                : 2,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
            mainAxisExtent: 250.0
        ),
        controller: _scrollController,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imageUrl: _images[index]['largeImageURL'],
                    likes: _images[index]['likes'],
                    views: _images[index]['views'],
                  ),
                ),
              );
            },
            child:  Card(
              child: Column(
                children: [
                  SizedBox(height: 200,
                    child: Image.network(
                      _images[index]['previewURL'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_images[index]['likes']} likes',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_images[index]['views']} views',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

