import 'package:flutter/material.dart';

class AddPostScreen extends StatelessWidget {
  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Post')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // handle image picking/upload later
          },
          child: const Text('Add Image Post'),
        ),
      ),
    );
  }
}
