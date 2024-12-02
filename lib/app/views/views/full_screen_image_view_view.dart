import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8), // Dark background
      body: Stack(
        children: [
          // Image in full screen
          Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.0,
            right: 16.0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30.0),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
            ),
          ),
        ],
      ),
    );
  }
}
