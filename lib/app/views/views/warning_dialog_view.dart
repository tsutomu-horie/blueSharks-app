import 'package:flutter/material.dart';

import 'package:get/get.dart';

class WarningDialogView {
  static void showWarningDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.yellow[700]), // Warning icon
              SizedBox(width: 8.0),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red, // Title text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.black), // Message text color
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(color: Colors.red), // Button text color
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

