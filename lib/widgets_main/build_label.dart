import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
    ),
  );
}