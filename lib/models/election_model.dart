import 'package:flutter/material.dart';

class ElectionModel {
  int? _id;
  String? _title;
  String? _description;
  DateTime? _startDate;
  DateTime? _endDate;

  int? get id => _id;
  String? get title => _title;
  String? get description => _description;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  ElectionModel(
      {required id,
      required title,
      required description,
      required startDate,
      required endDate}) {
    _id = id;
    _title = title;
    _description = description;
    _startDate = startDate;
    _endDate = endDate;
  }

  ElectionModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _title = json['title'];
    _description = json['description'];
    _startDate = json['startDate'];
    _endDate = json['endDate'];
  }
}
