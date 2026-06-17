import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  const EmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'username',
        suffixText: '@ascendion.com',
        border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
           ),
        ),
        focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(8),
         borderSide: const BorderSide(
           color: Color(0xFF757575), // dark grey
           width: 1.5,
          ),
        ),
      ),
    );
  }
}