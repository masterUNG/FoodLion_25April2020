import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

Future<void> normalToast(String message) async {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    backgroundColor: Colors.purple,
  );
}
