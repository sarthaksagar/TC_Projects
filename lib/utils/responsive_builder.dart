import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1100) return DeviceType.desktop;
    if (width >= 650) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;

  @override
  Widget build(BuildContext context) {
    return builder(context, getDeviceType(context));
  }
}
