import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_test_app/pages/Scanbot.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const appTitle = 'Drawer Demo';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

List<int> generateRandomList() {
  var rng = Random();
  var list = List<int>.generate(1000000, (_) => rng.nextInt(1000000));
  return list.toSet().toList();
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Container(),
      ),
      drawer: NavDrawer(),
    );
  }
}

class NavDrawer extends StatelessWidget {
  const NavDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Drawer Header'),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: const Text('Item 1'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const Page(title: "Item 1"),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.pedal_bike),
            title: const Text('BubbleSort'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SortView(),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.scanner),
            title: const Text('Scanbot'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ScanBot(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class Page extends StatelessWidget {
  final String title;

  const Page({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: NavDrawer(),
      body: SafeArea(
        child: Center(
            child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        )),
      ),
    );
  }
}

class SortView extends StatefulWidget {
  @override
  _SortViewState createState() => _SortViewState();
}

class _SortViewState extends State<SortView> {
  List<int> _list = [];
  double _timeTaken = 0.0;

  void bubbleSort(List<int> list) {
    print(" istarted");
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < list.length - i - 1; j++) {
        if (list[j] > list[j + 1]) {
          int temp = list[j];
          list[j] = list[j + 1];
          list[j + 1] = temp;
        }
      }
    }
  }

  void generateAndSortList() {
    var rng = Random();
    var list = List<int>.generate(100000, (_) => rng.nextInt(100000));
    setState(() {
      _list = list.toSet().toList();
    });
    var startTime = DateTime.now();
    bubbleSort(_list);
    var endTime = DateTime.now();
    setState(() {
      _timeTaken = endTime.difference(startTime).inMilliseconds.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sort View'),
      ),
      body: Column(
        children: <Widget>[
          Text('Time taken: ${_timeTaken.toStringAsFixed(3)} ms'),
          Expanded(
            child: ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_list[index].toString()),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generateAndSortList,
        child: Icon(Icons.sort),
      ),
    );
  }
}
