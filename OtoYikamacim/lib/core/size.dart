import 'package:flutter/widgets.dart';

class SizeConfig {
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double blockWidth = 0;
  static double blockHeight = 0;
  static double blockWidth2 = 0;
  static double blockHeight2 = 0;

  static void init(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;

    blockWidth = screenWidth / 360;
    blockHeight = screenHeight / 640;

    blockWidth2 = screenWidth / 399;
    blockHeight2 = screenHeight / 842;
  }

  static double getProportionateScreenWidth(double inputWidth) {
    return inputWidth * blockWidth;
  }

  static double getProportionateScreenHeight(double inputHeight) {
    return inputHeight * blockHeight;
  }

  static double getProportionateFontSize(double fontSize) {
    return fontSize * blockWidth;
  }

  static double getProportionateScreenWidth2(double inputWidth) {
    return inputWidth * blockWidth2;
  }

  static double getProportionateScreenHeight2(double inputHeight) {
    return inputHeight * blockHeight2;
  }

  static double getProportionateFontSize2(double fontSize) {
    return fontSize * blockWidth2;
  }
}
