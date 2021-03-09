import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../elements/element.dart';
import '../utilities/constants.dart';
import '../utilities/request.dart';
import 'flag_country.dart';

class _CallingCountry {
  final String fullName;
  final String code3Alpha;
  final String code2Alpha;
  final List<String> callingCode;

  _CallingCountry({
    required this.fullName,
    required this.callingCode,
    required this.code3Alpha,
    required this.code2Alpha,
  });

  _CallingCountry copy({
    String? fullName,
    List<String>? callingCode,
    String? code3Alpha,
    String? code2Alpha,
  }) {
    return _CallingCountry(
      fullName: fullName ?? this.fullName,
      callingCode: callingCode ?? this.callingCode,
      code3Alpha: code3Alpha ?? this.code3Alpha,
      code2Alpha: code2Alpha ?? this.code2Alpha,
    );
  }

  _CallingCountry.fromJson(Map<String, dynamic> map)
      : this.fullName = map["name"],
        this.code3Alpha = map["alpha3Code"],
        this.code2Alpha = map["alpha2Code"],
        this.callingCode =
            (map["callingCodes"] as List).map((c) => "+${c.trim()}").toList();

  @override
  int get hashCode {
    return this.fullName.hashCode ^ this.callingCode.hashCode;
  }

  @override
  bool operator ==(other) {
    _CallingCountry c = other as _CallingCountry;
    if (this.fullName == c.fullName && this.callingCode == c.callingCode) {
      return true;
    }
    return false;
  }
}

class PhoneTextField extends StatefulWidget {
  final PhoneNumberElement element;
  final TextEditingController? controller;
  final FocusNode? currentFocus;
  final FocusNode? nextFocus;
  final ValueNotifier<String>? errorNotifier;

  PhoneTextField({
    required this.element,
    this.controller,
    this.errorNotifier,
    this.currentFocus,
    this.nextFocus,
    Key? key,
  }) : super(key: key);

  @override
  _PhoneTextFieldState createState() => _PhoneTextFieldState();
}

class _PhoneTextFieldState extends State<PhoneTextField> {
  late ValueNotifier<_CallingCountry?> countryNotifier;

  @override
  void initState() {
    super.initState();
    countryNotifier = ValueNotifier(null);
  }

  @override
  Widget build(BuildContext context) {
    Widget iconFlag = ValueListenableBuilder<_CallingCountry?>(
      builder: (ctx, country, child) {
        if (country != null) {
          return Container(
            width: 48,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FlagCountry(
                flagURL: country.code2Alpha,
                flagSize: 32,
                width: 32,
                height: 32,
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
      valueListenable: countryNotifier,
    );
    Widget? prefixWidget = widget.element.showPrefix
        ? SizedBox(
      width: 55,
      height: 25,
      child: PrefixPhoneNumber(
        prefix: widget.element.initPrefix,
        countryNotifier: countryNotifier,
        title: widget.element.labelModalSheet,
      ),
    )
        : null;
    if (widget.errorNotifier != null) {
      return ValueListenableBuilder<String>(
        valueListenable: widget.errorNotifier!,
        builder: (ctx, error, child) {
          return TextFormField(
            controller: widget.controller,
            keyboardType: Constants.getInput(widget.element.typeInput),
            validator: widget.element.validator,
            readOnly: widget.element.readOnly,
            style: TextStyle(color: Colors.black),
            focusNode: widget.currentFocus,
            textInputAction: widget.nextFocus == null
                ? TextInputAction.done
                : TextInputAction.next,
            onFieldSubmitted: (v) {
              Constants.fieldFocusChange(
                  context, widget.currentFocus, widget.nextFocus);
            },
            decoration: Constants.setInputBorder(
                    context, widget.element.decorationElement)
                .copyWith(
              labelText: widget.element.label,
              hintText: widget.element.hint,
              errorText: error,
              prefix: prefixWidget,
              prefixIcon: widget.element.showPrefixFlag ? child : null,
              suffixIcon: widget.element.showSuffixFlag ? child : null,
            ),
          );
        },
        child: iconFlag,
      );
    }
    return TextFormField(
      controller: widget.controller,
      keyboardType: Constants.getInput(widget.element.typeInput),
      validator: widget.element.validator,
      readOnly: widget.element.readOnly,
      style: TextStyle(color: Colors.black),
      focusNode: widget.currentFocus,
      textInputAction: widget.nextFocus == null
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: (v) {
        Constants.fieldFocusChange(
            context, widget.currentFocus, widget.nextFocus);
      },
      decoration:
          Constants.setInputBorder(context, widget.element.decorationElement)
              .copyWith(
        labelText: widget.element.label,
        hintText: widget.element.hint,
        prefix: prefixWidget,
        prefixIcon: widget.element.showPrefixFlag ? iconFlag : null,
        suffixIcon: widget.element.showSuffixFlag ? iconFlag : null,
      ),
    );
  }
}

class PrefixPhoneNumber extends StatefulWidget {
  final String prefix;
  final String title;
  final bool showFlag;
  final ValueNotifier<_CallingCountry?> countryNotifier;

  PrefixPhoneNumber({
    this.prefix = "",
    this.title = "",
    this.showFlag = false,
    required this.countryNotifier,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrefixPhoneNumberState();
}

class _PrefixPhoneNumberState extends State<PrefixPhoneNumber> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (Platform.isIOS) {
          await showCupertinoModalPopup(
            context: context,
            builder: (ctx) {
              return _CallingCodeModalPopups(
                initCallingCode:
                    widget.countryNotifier.value?.callingCode.first ??
                        widget.prefix,
                title: widget.title,
                selectCallingCodeFunction: (callingCode) async {
                  widget.countryNotifier.value = callingCode;
                  Navigator.pop(ctx);
                },
              );
            },
          );
        } else {
          await showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5.0),
              topRight: Radius.circular(5.0),
            )),
            builder: (ctx) {
              return _CallingCodeModalPopups(
                initCallingCode:
                    widget.countryNotifier.value?.callingCode.first ??
                        widget.prefix,
                title: widget.title,
                selectCallingCodeFunction: (callingCode) async {
                  widget.countryNotifier.value = callingCode;
                  Navigator.pop(ctx);
                },
              );
            },
          );
        }
      },
      child: ValueListenableBuilder<_CallingCountry?>(
        valueListenable: widget.countryNotifier,
        builder: (ctx, country, _) {
          return Text(country?.callingCode.first ?? "");
        },
      ),
    );
  }
}

typedef SelectCallingCodeFunction = void Function(_CallingCountry);

class _CallingCodeModalPopups extends StatelessWidget {
  final String initCallingCode;
  final SelectCallingCodeFunction selectCallingCodeFunction;
  final String title;

  _CallingCodeModalPopups({
    this.title = "",
    this.initCallingCode = "",
    required this.selectCallingCodeFunction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3.0),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<_CallingCountry>>(
            future: Future.microtask(() async {
              return await getInformation<_CallingCountry>(
                (data) => _CallingCountry.fromJson(data),
              );
            }),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snap.hasData) {
                final list = snap.data!
                    .map(
                      (e) => e.callingCode
                          .map(
                            (c) => e.copy(callingCode: [c]),
                          )
                          .toList(),
                    )
                    .expand((element) => element)
                    .toList();
                return ListView.builder(
                  controller: ScrollController(
                    initialScrollOffset: list
                            .map((e) => e.callingCode.first)
                            .toList()
                            .indexOf(initCallingCode) *
                        31.5,
                  ),
                  itemExtent: 32,
                  itemBuilder: (ctx, index) {
                    final countryInfo = list[index];

                    return InkWell(
                      onTap: () {
                        selectCallingCodeFunction(countryInfo);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 12.0),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color:
                                countryInfo.callingCode.first == initCallingCode
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                          child: Row(
                            children: [
                              FlagCountry(
                                flagURL: countryInfo.code2Alpha,
                              ),
                              Flexible(
                                flex: 4,
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.0),
                                  child: Text(
                                    countryInfo.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              Flexible(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    countryInfo.callingCode.first,
                                    maxLines: 1,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: list.length,
                );
              }
              return SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
