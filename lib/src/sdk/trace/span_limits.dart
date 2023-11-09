// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

class SpanLimits {
  static const _DEFAULT_MAXNUM_ATTRIBUTES = 128;
  static const _DEFAULT_MAXNUM_EVENTS = 128;
  static const _DEFAULT_MAXNUM_LINKS = 128;
  static const _DEFAULT_MAXNUM_ATTRIBUTES_PER_EVENT = 128;
  static const _DEFAULT_MAXNUM_ATTRIBUTES_PER_LINK = 128;
  static const _DEFAULT_MAXNUM_ATTRIBUTES_LENGTH = -1;

  final int _maxNumAttributes;
  final int _maxNumEvents;
  final int _maxNumLink;
  final int _maxNumAttributesPerEvent;
  final int _maxNumAttributesPerLink;
  final int _maxNumAttributeLength;

  ///setters
  ///Set the max number of attributes per span
  set maxNumAttributes(int maxNumberOfAttributes) {
    if (maxNumberOfAttributes < 0) {
      throw ArgumentError('maxNumEvents must be greater or equal to zero');
    }
  }

  ///set the max number of events per span
  set maxNumEvents(int maxNumEvents) {
    if (maxNumEvents < 0) {
      throw ArgumentError('maxNumEvents must be greater or equal to zero');
    }
  }

  ///set the max number of links per span
  set maxNumLink(int maxNumLink) {
    if (maxNumLink < 0) {
      throw ArgumentError('maxNumEvents must be greater than or equal to zero');
    }
  }

  ///set the max number of attributes per event
  set maxNumAttributesPerEvent(int maxNumAttributesPerEvent) {
    if (maxNumAttributesPerEvent < 0) {
      throw ArgumentError('maxNumEvents must be greater than or equal to zero');
    }
  }

  ///set the max number of attributes per link
  set maxNumAttributesPerLink(int maxNumAttributesPerLink) {
    if (maxNumAttributesPerLink < 0) {
      throw ArgumentError('maxNumEvents must be greater than or equal to zero');
    }
  }

  ///return the maximum allowed attribute value length.
  ///This limits only applies to string and string list attribute valuse.
  ///Any string longer than this value will be truncated to this length.
  ///
  ///default is unlimited.
  set maxNumAttributeLength(int maxNumAttributeLength) {
    if (maxNumAttributeLength < 0) {
      throw ArgumentError('maxNumEvents must be greater than or equal to zero');
    }
  }

  ///getters
  ///return the max number of attributes per span
  int get maxNumAttributes => _maxNumAttributes;

  ///return the max number of events per span
  int get maxNumEvents => _maxNumEvents;

  ///return the max number of links per span
  int get maxNumLink => _maxNumLink;

  ///return the max number of attributes per event
  int get maxNumAttributesPerEvent => _maxNumAttributesPerEvent;

  ///return the max number of attributes per link
  int get maxNumAttributesPerLink => _maxNumAttributesPerLink;

  ///return the maximum allowed attribute value length.
  ///This limits only applies to string and string list attribute valuse.
  ///Any string longer than this value will be truncated to this length.
  ///
  ///default is unlimited.
  int get maxNumAttributeLength => _maxNumAttributeLength;

  const SpanLimits(
      {int maxNumAttributes = _DEFAULT_MAXNUM_ATTRIBUTES,
      int maxNumEvents = _DEFAULT_MAXNUM_EVENTS,
      int maxNumLink = _DEFAULT_MAXNUM_LINKS,
      int maxNumAttributesPerEvent = _DEFAULT_MAXNUM_ATTRIBUTES_PER_EVENT,
      int maxNumAttributesPerLink = _DEFAULT_MAXNUM_ATTRIBUTES_PER_LINK,
      int maxNumAttributeLength = _DEFAULT_MAXNUM_ATTRIBUTES_LENGTH})
      : _maxNumAttributes = maxNumAttributes,
        _maxNumEvents = maxNumEvents,
        _maxNumLink = maxNumLink,
        _maxNumAttributesPerEvent = maxNumAttributesPerEvent,
        _maxNumAttributesPerLink = maxNumAttributesPerLink,
        _maxNumAttributeLength = maxNumAttributeLength;
}
