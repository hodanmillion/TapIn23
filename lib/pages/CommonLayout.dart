import 'package:flutter/material.dart';

class CommonLayout extends StatelessWidget {
  final String title;
  final Widget body;

  const CommonLayout({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: body,
    );
  }
}