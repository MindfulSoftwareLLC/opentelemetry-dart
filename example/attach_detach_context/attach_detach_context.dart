// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:async';

import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart'
    show ConsoleExporter, SimpleSpanProcessor, TracerProviderBase;

void main() {
  final tp = TracerProviderBase(
          processors: [SimpleSpanProcessor(ConsoleExporter())]),
      tracer = tp.getTracer('instrumentation-name');

  final span = tracer.startSpan('root-1')..end();

  // Attach the root span to the current context (the root context) making the
  // span the current span until it is detached.
  final token = Context.attach(contextWithSpan(Context.current, span));

  final completer = Completer();

  // zone A
  // The created zone defines a run specification that will automatically attach
  // and detach the current context about any function that runs within the
  // zone.
  zone().run(() {
    final a = tracer.startSpan('zone-a-parent')..end();
    final context = contextWithSpan(Context.current, a);

    // zone B
    // A context given to the zone will be attached instead of the default
    // current context. In this case, the current context would contain the root
    // span attached to the parent zone, A.
    zone(context).run(() {
      tracer.startSpan('zone-b-child').end();
      completer.future.then((_) {
        // Since every attached context will have been detached by the time this
        // callback is invoked, the current context will be the root context.
        tracer.startSpan('zone-b-root').end();
      });
    });

    // Starting a span doesn't automatically attach the span. So to make the
    // parent span actually parent a span, its context needs to be attached.
    final token = Context.attach(context);
    tracer.startSpan('zone-a-child-1').end();
    if (!Context.detach(token)) {
      throw Exception('Failed to detach context');
    }

    // Alternatively, manually specifying the desired parent context avoids the
    // need to attach and detach the context.
    tracer.startSpan('zone-a-child-2', context: context).end();
  });

  if (!Context.detach(token)) {
    throw Exception('Failed to detach context');
  }

  completer.complete();

  tracer.startSpan('root-2').end();
}
