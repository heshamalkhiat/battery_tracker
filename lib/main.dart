// Battery Tracker Flutter App (with Save/Edit/Total and Persistent Storage)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(BatteryTrackerApp());

class BatteryTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: BatteryLogScreen(),
    );
  }
}

class ChargeEntry {
  String chargeDate;
  List<String> distances;
  List<String> dates;

  ChargeEntry({required this.chargeDate, required this.distances, required this.dates});

  int get totalKm => distances.fold<num>(
    0,
    (num sum, String val) => sum + (int.tryParse(val) ?? 0),
  ).toInt();

  Map<String, dynamic> toJson() => {
    'chargeDate': chargeDate,
    'distances': distances,
    'dates': dates,
  };

  factory ChargeEntry.fromJson(Map<String, dynamic> json) => ChargeEntry(
    chargeDate: json['chargeDate'],
    distances: List<String>.from(json['distances']),
    dates: List<String>.from(json['dates']),
  );
}

class BatteryLogScreen extends StatefulWidget {
  @override
  _BatteryLogScreenState createState() => _BatteryLogScreenState();
}

class _BatteryLogScreenState extends State<BatteryLogScreen> {
  final TextEditingController _dateController = TextEditingController();
  List<ChargeEntry> logs = [];

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonLogs = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList('battery_logs', jsonLogs);
  }

  Future<void> loadLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonLogs = prefs.getStringList('battery_logs');
    if (jsonLogs != null) {
      logs = jsonLogs.map((str) => ChargeEntry.fromJson(jsonDecode(str))).toList();
      setState(() {});
    }
  }

  void saveLog() {
    try {
      final inputDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      List<String> newDates = List.generate(4, (i) {
        return DateFormat('yyyy-MM-dd')
            .format(inputDate.add(Duration(days: i)));
      });
      List<String> newDistances = ["", "", "", ""];

      logs.add(ChargeEntry(
        chargeDate: _dateController.text,
        distances: newDistances,
        dates: newDates,
      ));
      _dateController.clear();
      saveToPrefs();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid date format. Use yyyy-MM-dd')),
      );
    }
  }

  void updateDistance(int logIndex, int dayIndex, String value) {
    logs[logIndex].distances[dayIndex] = value;
    saveToPrefs();
    setState(() {});
  }

  TextEditingController getController(String value) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Battery Charge Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Charge Date (yyyy-MM-dd)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: saveLog,
              child: Text('Add Charge Log'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, logIndex) {
                  final log = logs[logIndex];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Charge Date: ${log.chargeDate}', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            itemBuilder: (context, dayIndex) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Day ${dayIndex + 1}: ${log.dates[dayIndex]}'),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Distance (km)',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) => updateDistance(logIndex, dayIndex, val),
                                    controller: getController(log.distances[dayIndex]),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              );
                            },
                          ),
                          Text('Total Distance: ${log.totalKm} km', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
