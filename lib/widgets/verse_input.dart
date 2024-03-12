import "package:flutter/material.dart";

Future<int> showNumberInputDialog(BuildContext context) async {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _errorMessage;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Enter a Number (1-50)'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              errorText: _errorMessage,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a number';
              }
              int? number = int.tryParse(value);
              if (number == null || number < 1 || number > 50) {
                return 'Please enter a number between 1 and 50';
              }
              return null; // Indicates valid input
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Input is valid, process the number here
                final validNumber = int.parse(_controller.text);
                print('Valid number: $validNumber');

                Navigator.pop(context); // Close the dialog
              }
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );

  if (_formKey.currentState!.validate()) {
    final validNumber = int.parse(_controller.text);
    return validNumber;
  } else {
    return 0;
  }
}