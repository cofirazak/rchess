import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockfish/stockfish.dart';
import 'package:system_info_plus/system_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  late Stockfish stockfish;
  String output = '';
  int _deviceMemory = -1;

  @override
  void initState() {
    super.initState();
    stockfish = Stockfish();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    int deviceMemory;

    try {
      deviceMemory = await SystemInfoPlus.physicalMemory ?? -1;
    } on PlatformException {
      deviceMemory = -1;
    }
    if (!mounted) return;

    setState(() {
      _deviceMemory = deviceMemory;
    });
  }

  sumStream() async {
    await for (final value in stockfish.stdout) {
      print('main.dart:25 : '+value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Stockfish example app'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: stockfish.state,
                builder: (_, __) => Text(
                  'stockfish.state=${stockfish.state.value}',
                  key: ValueKey('stockfish.state'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: stockfish.state,
                builder: (_, __) => ElevatedButton(
                  onPressed: stockfish.state.value == StockfishState.disposed
                      ? () {
                          final newInstance = Stockfish();
                          setState(() => stockfish = newInstance);
                        }
                      : null,
                  child: Text('Reset Stockfish instance'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Custom UCI command',
                  hintText: 'go infinite',
                ),
                onSubmitted: (value) => stockfish.stdin = value,
                textInputAction: TextInputAction.send,
              ),
            ),
            Wrap(
              children: [
                'setoption name threads value ${Platform.numberOfProcessors}',
                'setoption name hash value ${_deviceMemory / 8}',
                'setoption name multipv value 3',
                'setoption name UCI_AnalyseMode value true',
                'position fen n2Bqk2/5p1p/Q4KP1/p7/8/8/8/8 w - - 0 1',
                'go nodes 2250000',
                'bench 64 ${Platform.numberOfProcessors} ',
              ]
                  .map(
                    (command) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => stockfish.stdin = command,
                        child: Text(command),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      StreamBuilder(
                        stream: stockfish.stdout,
                        builder:
                            (BuildContext context, AsyncSnapshot<String> snapshot) {
                          // print('streambuilder запустился');
                          output += snapshot.data ?? '';
                          return Text(output);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
