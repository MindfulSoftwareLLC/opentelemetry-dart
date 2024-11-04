// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

@TestOn('vm')

import 'dart:async';

import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;
import 'package:opentelemetry/src/experimental_api.dart';
import 'package:opentelemetry/src/sdk/trace/span.dart';
import 'package:test/test.dart';

void main() {
  final testSpanContext = api.SpanContext(api.TraceId([1, 2, 3]),
      api.SpanId([7, 8, 9]), api.TraceFlags.none, api.TraceState.empty());
  final testSpan = Span(
      'foo',
      testSpanContext,
      api.SpanId([4, 5, 6]),
      [],
      sdk.DateTimeTimeProvider(),
      sdk.Resource([]),
      sdk.InstrumentationScope(
          'library_name', 'library_version', 'url://schema', []),
      api.SpanKind.client,
      [],
      sdk.SpanLimits(),
      sdk.DateTimeTimeProvider().now);

  group('contextWithSpan', () {
    test('returns a new Context with the Span', () {
      final context = api.contextWithSpan(api.Context.current, testSpan);
      expect(api.Context.current, isNot(same(context)));
      expect(api.spanFromContext(context), same(testSpan));
    });
  });

  group('contextWithSpanContext', () {
    test('returns a new Context with the SpanContext', () {
      final context =
          api.contextWithSpanContext(api.Context.current, testSpanContext);
      expect(api.Context.current, isNot(same(context)));
      expect(api.spanContextFromContext(context), same(testSpanContext));
    });
  });

  group('spanFromContext', () {
    test('returns Span when exists', () {
      final context = api.contextWithSpan(api.Context.current, testSpan);
      expect(api.spanFromContext(context), same(testSpan));
    });

    test('returns an invalid Span when Span doesn\'t exist', () {
      final context = api.Context.current;
      expect(api.spanFromContext(context), isA<NonRecordingSpan>());
      expect(api.spanContextFromContext(context).isValid, isFalse);
    });
  });

  group('spanContextFromContext', () {
    test('returns SpanContext when Span exists', () {
      final testContext = api.contextWithSpan(api.Context.current, testSpan);
      expect(api.spanContextFromContext(testContext), same(testSpanContext));
    });

    test('returns an invalid SpanContext when Span doesn\'t exist', () {
      expect(api.spanContextFromContext(api.Context.current).isValid, isFalse);
    });
  });

  group('Context.current', () {
    test('returns root context', () {
      expect(api.Context.current, same(api.Context.root));
    });

    test('returns zone context', () {
      final context = api.Context.root.setValue(api.ContextKey(), 'c');
      api.zone(context).run(() => expect(api.Context.current, same(context)));
    });

    test('returns root stack attached context', () {
      final context = api.Context.root.setValue(api.ContextKey(), 'c');
      final token = api.Context.attach(context);
      expect(api.Context.current, same(context));
      api.Context.detach(token);
    });

    test('returns non-root stack attached context', () {
      api.zone().run(() {
        final attached = api.Context.root.setValue(api.ContextKey(), 'a');
        final token = api.Context.attach(attached);
        expect(api.Context.current, same(attached));
        api.Context.detach(token);
      });
    });

    test('returns zone context after detach', () {
      final attached = api.Context.root.setValue(api.ContextKey(), 'foo');
      final token = api.Context.attach(attached);

      final zone = api.Context.root.setValue(api.ContextKey(), 'bar');
      api.zone(zone).run(() {
        api.Context.detach(token);
        expect(api.Context.current, same(zone));
      });
    });
  });

  group('Context.detach', () {
    test('returns true on match', () {
      final token = api.Context.attach(api.Context.current);
      expect(api.Context.detach(token), isTrue);
    });

    test('returns false on mismatch', () {
      final token1 = api.Context.attach(api.Context.current);
      final token2 = api.Context.attach(api.Context.current);
      expect(api.Context.detach(token1), isFalse);
      expect(api.Context.detach(token2), isTrue);
    });

    test('returns true on match in default zone', () {
      final token1 = api.Context.attach(api.Context.current);
      Zone.current.fork().run(() {
        expect(api.Context.detach(token1), isTrue);

        final token2 = api.Context.attach(api.Context.current);
        expect(api.Context.detach(token2), isTrue);
      });
    });

    test('returns false on mismatch in otel zone', () {
      final token1 = api.Context.attach(api.Context.current);
      api.zone(api.Context.current).run(() {
        expect(api.Context.detach(token1), isFalse);

        final token2 = api.Context.attach(api.Context.current);
        expect(api.Context.detach(token2), isTrue);
      });
    });

    test('returns true on match in default nested zone', () {
      final token1 = api.Context.attach(api.Context.current);
      Zone.current.fork().run(() {
        final token2 = api.Context.attach(api.Context.current);
        Zone.current.fork().run(() {
          expect(api.Context.detach(token2), isTrue);
          expect(api.Context.detach(token1), isTrue);
        });
      });
    });
  });
}
