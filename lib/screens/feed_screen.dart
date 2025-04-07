import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _pickedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_pickedImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseStorage.instance
        .ref()
        .child("posts")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(_pickedImage!);
    final imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('posts').add({
      'caption': _captionController.text,
      'imageUrl': imageUrl,
      'userId': user!.uid,
      'likes': [],
      'timestamp': FieldValue.serverTimestamp()
    });

    _captionController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  void _toggleLike(String postId, List likes) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (likes.contains(uid)) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

  void _deletePost(String postId, String postUserId) async {
    if (FirebaseAuth.instance.currentUser!.uid == postUserId) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("InstaClone Feed"),
        actions: [
          IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          if (_pickedImage != null) Image.file(_pickedImage!, height: 200),
          TextField(controller: _captionController, decoration: const InputDecoration(labelText: 'Caption')),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(Icons.image)),
              ElevatedButton(onPressed: _uploadPost, child: const Text("Post"))
            ],
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (ctx, i) {
                    final post = posts[i];
                    final data = post.data() ;
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(data['imageUrl']),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['caption'] ?? ''),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  data['likes'].contains(user!.uid) ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () => _toggleLike(post.id, List.from(data['likes'])),
                              ),
                              Text('${data['likes'].length} likes'),
                              if (data['userId'] == user.uid)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deletePost(post.id, data['userId']),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
