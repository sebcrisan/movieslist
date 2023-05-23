import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// provider scope
void main() {
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persons App',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Persons App'),
    );
  }
}

// Home page screen
class MyHomePage extends ConsumerWidget {
  /// Init homepage
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  /// The title of the homepage
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persons'),
      ),
    );
  }
}
