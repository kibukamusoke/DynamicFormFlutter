import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './simple_dynamic_form.dart';
import 'decoration_element.dart';
import 'element.dart';
import 'group_elements.dart';
import 'utilities/constants.dart';

typedef onAction = Future<void> Function(
    String cardNumber, String cvv, String dateExpiration);

class PaymentForm extends StatefulWidget {
  final DecorationElement decorationElement;
  final String labelCardNumber;
  final String labelDateExpiration;
  final String labelCVV;
  final String errorMessageDateExpiration;
  final String errorMessageCVV;
  final String errorMessageCardNumber;
  final String errorIsRequiredMessage;
  final onAction actionPayment;
  final Text paymentText;
  final ButtonDecorationElement buttonDecoration;

  PaymentForm({
    this.decorationElement,
    this.errorMessageDateExpiration,
    this.labelCardNumber,
    this.labelDateExpiration,
    this.labelCVV,
    this.errorMessageCVV,
    this.errorMessageCardNumber,
    this.errorIsRequiredMessage,
    this.actionPayment,
    this.paymentText,
    this.buttonDecoration,
    Key key,
  }) : super(
          key: key,
        );

  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final dateFormat = DateFormat("MM/yy");
  final dateFormatCompare = DateFormat("MM/yyyy");
  DateTime startedDate;

  DateTime endDate;

  GlobalKey<SimpleDynamicFormState> globalKey;

  static const String idCardNumber = "id-card-number";
  static const String idCVV = "id-cvv";
  static const String idDateExpiration = "id-date-expiration";
  String yearStartedInputFormat = "";
  String yearEndInputFormat = "";
  RegExp reg;

  @override
  void initState() {
    super.initState();
    globalKey = GlobalKey<SimpleDynamicFormState>();
    startedDate = DateTime.now().parseFormat(dateFormat);
    endDate = DateTime.now().add(Duration(days: 3650)).parseFormat(dateFormat);

    yearStartedInputFormat = startedDate.year.toString();
    yearEndInputFormat = endDate.year.toString();
    reg = RegExp(
        "^((0[1-9])|(1[0-2]))(\/)((${yearStartedInputFormat[0]}[0-9])|($yearEndInputFormat))\$");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SimpleDynamicForm(
          key: globalKey,
          groupElements: [
            GroupElement(
              directionGroup: DirectionGroup.Vertical,
              margin: const EdgeInsets.only(top: 5.0, bottom: 3.0),
              textElements: [
                CardNumberElement(
                  id: idCardNumber,
                  label: widget.labelCardNumber,
                  decorationElement: widget.decorationElement,
                ),
              ],
            ),
            GroupElement(
              directionGroup: DirectionGroup.Horizontal,
              sizeElements: [0.5, 0.5],
              textElements: [
                DateInputElement(
                  id: idDateExpiration,
                  decorationElement: widget.decorationElement,
                  isRequired: true,
                  requiredErrorMsg: widget.errorIsRequiredMessage,
                  label: widget.labelDateExpiration,
                  hint: "mm/yy",
                  dateFormat: dateFormat,
                  initDate: startedDate,
                  validator: (v) {
                    try {
                      if (!reg.hasMatch(v)) {
                        return widget.errorMessageDateExpiration;
                      }
                      var d = dateFormatCompare.parse(v);
                      if (d.isBefore(startedDate) || d.isAfter(endDate)) {
                        return widget.errorMessageDateExpiration;
                      }
                    } catch (e) {
                      return widget.errorMessageDateExpiration;
                    }
                    return null;
                  },
                ),
                TextElement(
                    id: idCVV,
                    decorationElement: widget.decorationElement,
                    isRequired: true,
                    typeInput: TypeInput.Numeric,
                    label: widget.labelCVV,
                    hint: widget.labelCVV,
                    error: widget.errorIsRequiredMessage,
                    validator: (v) {
                      if (v.length != 3) {
                        return widget.errorMessageCVV;
                      }
                      return null;
                    }),
              ],
            ),
          ],
        ),
        RaisedButton(
          onPressed: () async {
            if (globalKey.currentState.validate()) {
              final cardNumber =
                  globalKey.currentState.singleValueById(idCardNumber);
              final cvv = globalKey.currentState.singleValueById(idCVV);
              final dateExpiration =
                  globalKey.currentState.singleValueById(idDateExpiration);
              await widget.actionPayment(cardNumber, cvv, dateExpiration);
            }
          },
          child: widget.paymentText ?? Text("purchase"),
        ),
      ],
    );
  }
}
