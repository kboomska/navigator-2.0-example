import 'package:flutter/material.dart';

void main() {
  runApp(const Nav2App());
}

class Nav2App extends StatelessWidget {
  const Nav2App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
          child: const Text('View Details'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const DetailScreen();
              }),
            );
          },
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
          child: const Text('Pop!'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}