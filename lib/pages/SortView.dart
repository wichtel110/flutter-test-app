import 'dart:math';

import 'package:flutter/material.dart';

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
