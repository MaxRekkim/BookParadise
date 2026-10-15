import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookCoverWidget extends StatelessWidget {
  final String? coverURL;
  final String title;
  final String author;
  final double cornerRadius;
  final double? width;
  final double? height;

  const BookCoverWidget({
    super.key,
    this.coverURL,
    required this.title,
    required this.author,
    this.cornerRadius = 8.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = coverURL != null && coverURL!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        child: validUrl
            ? CachedNetworkImage(
                imageUrl: coverURL!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(context),
                errorWidget: (context, url, error) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
            Theme.of(context).colorScheme.secondary.withOpacity(0.85),
          ],
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, color: Colors.white70, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
