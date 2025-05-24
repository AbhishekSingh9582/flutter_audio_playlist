import 'package:flutter/material.dart';

class AudioPlayerThemeData {
  final Color? screenBackgroundColor;
  final Gradient? screenBackgroundGradient;
  final Color? primaryContentColor;
  final Color? secondaryContentColor;

  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? trackTimeTextStyle;
  final TextStyle? upNextTitleStyle;
  final TextStyle? upNextCardTextStyle;

  final SliderThemeData? sliderThemeData;

  final Color? controlButtonColor;
  final Color? controlButtonIconColor;
  final Color? activeControlButtonColor;
  final Color? playPauseButtonColor;
  final Color? playPauseButtonIconColor;

  final double? albumArtBorderRadius;
  final EdgeInsetsGeometry? screenPadding;
  final double? spacingBetweenElements;
  final double? controlButtonSize;
  final double? playPauseButtonSize;

  final bool showShuffleButton;
  final bool showRepeatButton;
  final bool showSleepTimerButton;
  final bool showUpNextSection;
  final bool useDominantColorForBackground;

  final BoxDecoration? upNextCardDecoration;
  final EdgeInsetsGeometry? upNextCardPadding;
  final Size? upNextCardItemSize;
  final Color? upNextCardBackgroundColor;

  final IconData? backButtonIcon;
  final Color? backButtonColor;

  const AudioPlayerThemeData({
    this.screenBackgroundColor,
    this.screenBackgroundGradient,
    this.primaryContentColor,
    this.secondaryContentColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.trackTimeTextStyle,
    this.upNextTitleStyle,
    this.upNextCardTextStyle,
    this.sliderThemeData,
    this.controlButtonColor,
    this.controlButtonIconColor,
    this.activeControlButtonColor,
    this.playPauseButtonColor,
    this.playPauseButtonIconColor,
    this.albumArtBorderRadius,
    this.screenPadding,
    this.spacingBetweenElements,
    this.controlButtonSize,
    this.playPauseButtonSize,
    this.showShuffleButton = true,
    this.showRepeatButton = true,
    this.showSleepTimerButton = true,
    this.showUpNextSection = true,
    this.useDominantColorForBackground = true,
    this.upNextCardDecoration,
    this.upNextCardPadding,
    this.upNextCardItemSize,
    this.upNextCardBackgroundColor,
    this.backButtonIcon,
    this.backButtonColor,
  });
}

class AudioPlayerTheme extends InheritedWidget {
  final AudioPlayerThemeData data;

  const AudioPlayerTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static AudioPlayerThemeData? of(BuildContext context) {
    final AudioPlayerTheme? result =
        context.dependOnInheritedWidgetOfExactType<AudioPlayerTheme>();
    return result?.data;
  }

  @override
  bool updateShouldNotify(AudioPlayerTheme oldWidget) {
    return data != oldWidget.data;
  }
}
