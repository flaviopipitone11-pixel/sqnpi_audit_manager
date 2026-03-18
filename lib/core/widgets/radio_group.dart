import 'package:flutter/material.dart';

class CustomRadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Widget child;

  const CustomRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _CustomRadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

class _CustomRadioGroupScope<T> extends InheritedWidget {
  final T groupValue;
  final ValueChanged<T> onChanged;

  const _CustomRadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static _CustomRadioGroupScope<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CustomRadioGroupScope<T>>();
  }

  @override
  bool updateShouldNotify(_CustomRadioGroupScope<T> oldWidget) =>
      groupValue != oldWidget.groupValue;
}

class CustomRadioOption<T> extends StatelessWidget {
  final String label;
  final T value;

  const CustomRadioOption({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scope = _CustomRadioGroupScope.of<T>(context);
    return RadioListTile<T>(
      title: Text(label),
      value: value,
      groupValue: scope?.groupValue,
      onChanged: scope != null ? (v) => scope.onChanged(v as T) : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
