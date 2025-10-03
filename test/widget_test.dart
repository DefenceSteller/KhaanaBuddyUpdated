import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaanabuddy/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our simple test app and trigger a frame.
    await tester.pumpWidget( MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

/// A minimal app used only for this unit test.
/// Using this avoids needing `MyApp` from your real app.
class _TestApp extends StatefulWidget {
  const _TestApp({super.key});

  @override
  State<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<_TestApp> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: Center(child: Text('$_counter', style: const TextStyle(fontSize: 32))),
        floatingActionButton: FloatingActionButton(
          onPressed: _increment,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
