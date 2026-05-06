import 'package:flutter/material.dart';

void main() {
  RadioGroup<int>(
    groupValue: 0,
    onChanged: (v) {},
    child: Column(
      children: [
        Radio<int>(value: 0),
        Radio<int>(value: 1),
      ],
    ),
  );
}
