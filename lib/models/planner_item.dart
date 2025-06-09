import 'package:flutter/material.dart';

class PlannerItem {
  String id;
  String place;
  TimeOfDay time;
  DateTime date;
  double price;

  PlannerItem({
    required this.id,
    required this.place,
    required this.time,
    required this.date,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place': place,
      'time': '${time.hour}:${time.minute}',
      'date': date.toIso8601String(),
      'price': price,
    };
  }

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return PlannerItem(
      id: json['id'],
      place: json['place'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      date: DateTime.parse(json['date']),
      price: (json['price'] as num).toDouble(),
    );
  }
}
