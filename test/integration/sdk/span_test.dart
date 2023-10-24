// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

@TestOn('vm')
import 'package:mockito/mockito.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;
import 'package:opentelemetry/src/sdk/trace/span.dart';
import 'package:test/test.dart';

import '../../unit/mocks.dart';

void main() {
  test('span set and end time', () {
    final mockProcessor1 = MockSpanProcessor();
    final mockProcessor2 = MockSpanProcessor();
    final parentSpanId = api.SpanId([4, 5, 6]);
    final parentSpanContext = api.Context.root;
    final span = Span(
        'foo',
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([7, 8, 9]),
            api.TraceFlags.none, api.TraceState.empty()),
        parentSpanId,
        [mockProcessor1, mockProcessor2],
        sdk.DateTimeTimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationScope(
            'library_name', 'library_version', 'url://schema', []),
        api.SpanKind.internal,
        [],
        [],
        parentSpanContext,
        sdk.SpanLimits(),
        sdk.DateTimeTimeProvider().now);

    expect(span.startTime, isNotNull);
    expect(span.endTime, isNull);
    expect(span.parentSpanId, same(parentSpanId));
    expect(span.name, 'foo');

    verify(mockProcessor1.onStart(span, parentSpanContext)).called(1);
    verify(mockProcessor2.onStart(span, parentSpanContext)).called(1);
    verifyNever(mockProcessor1.onEnd(span));
    verifyNever(mockProcessor2.onEnd(span));

    span.end();
    expect(span.startTime, isNotNull);
    expect(span.endTime, isNotNull);
    expect(span.endTime, greaterThan(span.startTime));

    verify(mockProcessor1.onEnd(span)).called(1);
    verify(mockProcessor2.onEnd(span)).called(1);
  });

  test('span status', () {
    final span = Span(
        'foo',
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([7, 8, 9]),
            api.TraceFlags.none, api.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        sdk.DateTimeTimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationScope(
            'library_name', 'library_version', 'url://schema', []),
        api.SpanKind.client,
        [],
        [],
        api.Context.root,
        sdk.SpanLimits(),
        sdk.DateTimeTimeProvider().now);

    // Verify span status' defaults.
    expect(span.status.code, equals(api.StatusCode.unset));
    expect(span.status.description, equals(null));

    // Verify that span status can be set to "Error".
    span.setStatus(api.StatusCode.error, 'Something s\'ploded.');
    expect(span.status.code, equals(api.StatusCode.error));
    expect(span.status.description, equals('Something s\'ploded.'));

    // Verify that multiple errors update the span to the most recently set.
    span.setStatus(api.StatusCode.error, 'Another error happened.');
    expect(span.status.code, equals(api.StatusCode.error));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status cannot be set to "Unset" and that description
    // is ignored for statuses other than "Error".
    span.setStatus(api.StatusCode.unset, 'Oops.  Can we turn this back off?');
    expect(span.status.code, equals(api.StatusCode.error));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status can be set to "Ok" and that description is
    // ignored for statuses other than "Error".
    span.setStatus(api.StatusCode.ok, 'All done here.');
    expect(span.status.code, equals(api.StatusCode.ok));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status cannot be changed once set to "Ok".
    span.setStatus(api.StatusCode.error, 'Something else went wrong.');
    expect(span.status.code, equals(api.StatusCode.ok));
    expect(span.status.description, equals('Another error happened.'));
  });

  test('span add and retrieve attributes', () {
    final attributeList = [
      api.Attribute.fromString('First', 'First Attribute'),
      api.Attribute.fromBoolean('Second', false),
      api.Attribute.fromDouble('Third', 3.14),
      api.Attribute.fromInt('Fourth', 4),
      api.Attribute.fromStringList('Fifth', ['String', 'List']),
      api.Attribute.fromBooleanList('Sixth', [true, false]),
      api.Attribute.fromDoubleList('Seventh', [7.1, 7.2]),
      api.Attribute.fromIntList('Eighth', [8, 8]),
    ];
    final expectedAttributeMap = {
      'First': 'First Attribute',
      'Second': false,
      'Third': 3.14,
      'Fourth': 4,
      'Fifth': ['String', 'List'],
      'Sixth': [true, false],
      'Seventh': [7.1, 7.2],
      'Eighth': [8, 8],
    };
    final span = Span(
        'foo',
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([7, 8, 9]),
            api.TraceFlags.none, api.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        sdk.DateTimeTimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationScope(
            'library_name', 'library_version', 'url://schema', []),
        api.SpanKind.client,
        [],
        [],
        api.Context.root,
        sdk.SpanLimits(),
        sdk.DateTimeTimeProvider().now);

    expect(span.attributes.keys.length, isZero);

    span.attributes.add(attributeList.removeAt(0));
    span.attributes.addAll(attributeList);

    span.end();

    expectedAttributeMap.forEach((key, value) {
      expect(span.attributes.get(key).runtimeType, equals(value.runtimeType));
      expect(span.attributes.get(key), equals(value));
    });
  });

  test('span record error', () {
    final span = Span(
        'foo',
        api.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([7, 8, 9]),
            api.TraceFlags.none, api.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        sdk.DateTimeTimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationScope(
            'library_name', 'library_version', 'url://schema', []),
        api.SpanKind.client,
        [],
        [],
        api.Context.root,
        sdk.SpanLimits(),
        sdk.DateTimeTimeProvider().now);

    try {
      throw Exception('Oh noes!');
    } catch (e, s) {
      span.recordException(e, stackTrace: s);
    }

    expect(span.attributes.get(api.SemanticAttributes.exceptionType),
        equals('_Exception'));
    expect(span.attributes.get(api.SemanticAttributes.exceptionMessage),
        equals('Exception: Oh noes!'));
  });
}
