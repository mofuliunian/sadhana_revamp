import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sadhana/utils/apputils.dart';

class NumberInput extends StatelessWidget {
  const NumberInput({
    Key key,
    this.labelText,
    this.valueText,
    this.enabled,
    this.onSaved,
    this.digitOnly = true,
    this.isRequiredValidation = false,
    this.validation
  }) : super(key: key);

  final String labelText;
  final String valueText;
  final bool digitOnly;
  final bool enabled;
  final bool isRequiredValidation;
  final Function(double) onSaved;
  final Function(double) validation;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      alignment: Alignment.bottomLeft,
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
        initialValue: valueText,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: digitOnly ? [WhitelistingTextInputFormatter.digitsOnly] : null,
        onSaved: (value) {
          if(onSaved != null)
            onSaved(double.parse(value));
          return value;
        },
        validator: (value) {
          if (isRequiredValidation && value.isEmpty) {
            return '$labelText is required';
          } else if(!AppUtils.isNumeric(value)) {
            return 'Invalid $labelText';
          }
          if(validation != null)
            return validation(double.parse(value));
        },
      ),
    );
  }
}
