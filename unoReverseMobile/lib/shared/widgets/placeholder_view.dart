import 'package:flutter/material.dart';

class PlaceholderView extends StatelessWidget {
  const PlaceholderView(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}
