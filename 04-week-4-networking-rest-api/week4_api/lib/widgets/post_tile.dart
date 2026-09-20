import 'package:flutter/material.dart';
import '../data/models/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  const PostTile({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${post.id}'),
        ),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(post.body),
        ),
      ),
    );
  }
}