import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class EventsPlugin extends PlatformInterface {
  static final Object _token = Object();
  EventsPlugin() : super(token: _token) {
    PlatformInterface.verifyToken(this, _token);
  }

  final channel = const MethodChannel('events_plugin');

  Future<String?> getPlatformVersion() async {
    final version = await channel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  Future<bool?> hasAccess() async =>
      await channel.invokeMethod<bool>('hasAccess');

  Future<bool?> requestAccess() async =>
      await channel.invokeMethod<bool>('requestAccess');

  Future<AppleCalendar?> getDefaultCalendar() async {
    final list =
        await channel.invokeMapMethod<String, String>('getDefaultCalendar');
    if (list case {'title': final title, 'id': final id}) {
      return AppleCalendar(title: title, id: id);
    }
    return null;
  }

  Future<List<AppleCalendar>> getCalendars() async {
    final calendars =
        await channel.invokeListMethod<Map<Object?, Object?>>('getCalendars');
    if (calendars == null) return [];
    return calendars
        .map<AppleCalendar>((calendar) => AppleCalendar(
            title: calendar['title']! as String, id: calendar['id']! as String))
        .toList();
  }

  Future<List<AppleEvent>> getEvents(AppleCalendar list) async {
    final events = await channel
        .invokeListMethod<Map<Object?, Object?>>('getEvents', {'id': list.id});
    if (events == null) return [];
    return events
        .map<AppleEvent>((event) => AppleEvent.fromJson(event))
        .toList();
  }
}

class AppleEvent {
  String calendar;
  final String id;
  final String title;
  DateTime? startDate;
  DateTime? endDate;
  String location;
  bool isAllDay;
  String notes;

  AppleEvent.fromJson(Map<Object?, Object?> json)
      : calendar = json['calendar'] as String,
        id = json['id'] as String,
        title = json['title'] as String,
        startDate = json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        endDate = json['endDate'] != null
            ? DateTime.tryParse(json['endDate'] as String)
            : null,
        location = json['location'] as String,
        isAllDay = json['isAllDay'] == 'true',
        notes = json['notes'] as String;

  @override
  String toString() =>
      '$title start $startDate for ${endDate?.difference(startDate!).inMinutes}\t$notes';
}

class AppleCalendar {
  final String title;
  final String id;
  AppleCalendar({required this.title, required this.id});

  @override
  String toString() => title;
}
