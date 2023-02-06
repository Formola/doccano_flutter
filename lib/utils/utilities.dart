import 'dart:math';

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

int hexStringToInt(String hexString) =>
    int.parse("0xFF${hexString.substring(1)}");

//per non tagliare a metà parole nel testo mostrato in validation page
void updateTextSpan(List<InlineSpan> inlineSpanList) {
  inlineSpanList.first = (inlineSpanList.first as TextSpan).copyWith(
      text: (inlineSpanList.first.toPlainText().contains(" "))
          ? inlineSpanList.first
              .toPlainText()
              .substring(inlineSpanList.first.toPlainText().indexOf(" "))
              .substring(1)
          : inlineSpanList.first.toPlainText());

  inlineSpanList.last = (inlineSpanList.last as TextSpan).copyWith(
      text: inlineSpanList.last
          .toPlainText()
          .substring(0, inlineSpanList.last.toPlainText().lastIndexOf(" ")));
}

void fixData(Map<String, dynamic> commentMap) {
  if (commentMap.containsKey('data sentenza')) {
    commentMap.update('data sentenza',
        (value) => value.toString().substring(0, value.toString().length - 3));
  }
}

void controllerRandomTopBottom(CardSwiperController controller) {
  var directions = <String>['top', 'bottom'];
  var random = Random();
  int i = random.nextInt(directions.length);
  String randomString = directions[i];
  if (randomString == 'top') {
    controller.swipeTop();
  } else {
    controller.swipeBottom();
  }
}
