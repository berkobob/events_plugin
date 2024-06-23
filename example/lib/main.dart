import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:events_plugin/events_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _eventsPlugin = EventsPlugin();
  bool _hasAccess = false;
  AppleCalendar? _defaultCalendar;
  List<AppleCalendar> _calendars = [];
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _eventsPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _defaultCalendar = await _eventsPlugin.getDefaultCalendar();
    _calendars = await _eventsPlugin.getCalendars();

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> requestAccess() async {
    _hasAccess = await _eventsPlugin.requestAccess() ?? false;
    setState(() {});
  }

  Future<void> getEvents(AppleCalendar calendar) async {
    final events = await _eventsPlugin.getEvents(calendar);
    setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: _hasAccess
                  ? Text('Default calendar: $_defaultCalendar')
                  : TextButton(
                      onPressed: requestAccess,
                      child: const Text('Request access'),
                    ),
              actions: [Text(_platformVersion)],
            ),
            body: Row(
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _calendars
                        .map<ListTile>((calendar) => ListTile(
                            title: TextButton(
                                onPressed: () => getEvents(calendar),
                                child: Text(calendar.title))))
                        .toList(),
                  ),
                ),
                Flexible(
                  child: ListView(
                      shrinkWrap: true,
                      children: _events
                          .map<ListTile>((event) => ListTile(
                                title: Text(event.title),
                              ))
                          .toList()),
                )
              ],
            )));
  }
}
