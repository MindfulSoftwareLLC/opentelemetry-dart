import 'dart:async';

import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart'
    show ConsoleExporter, SimpleSpanProcessor, TracerProviderBase;
import 'package:opentelemetry/src/experimental_api.dart'
    show registerGlobalContextManager, ZoneContextManager;

final _tokenToContext = <Symbol, Context>{};
final _tokenToZone = <Symbol, Zone>{};
final _zoneToTokens = <Zone, List<Symbol>>{};

Symbol createToken(Zone zone, Context context) {
  return Symbol('${identityHashCode(zone)}-${identityHashCode(context)}');
}

Symbol attach(Context context) {
  final token = createToken(Zone.current, context);
  _tokenToContext.putIfAbsent(token, () => context);
  _tokenToZone.putIfAbsent(token, () => Zone.current);
  _zoneToTokens.putIfAbsent(Zone.current, () => []).add(token);
  return token;
}

void detach(Symbol token) {
  _tokenToContext.remove(token);
  final zone = _tokenToZone.remove(token);
  if (zone != null) _zoneToTokens[zone]?.remove(token);
}

Context currentOtelContext() {
  final tokens = _zoneToTokens[Zone.current];
  if (tokens == null || tokens.isEmpty) return globalContextManager.active;
  return _tokenToContext[tokens.last] ?? globalContextManager.active;
}

void main(List<String> args) async {
  final tp =
      TracerProviderBase(processors: [SimpleSpanProcessor(ConsoleExporter())]);
  registerGlobalTracerProvider(tp);

  final cm = ZoneContextManager();
  registerGlobalContextManager(cm);

  final span = tp.getTracer('instrumentation-name').startSpan('test-span-0');

  final token = attach(contextWithSpan(cm.active, span));

  tp
      .getTracer('instrumentation-name')
      .startSpan('test-span-1', context: currentOtelContext())
      .end();

  detach(token);

  tp
      .getTracer('instrumentation-name')
      .startSpan('test-span-2', context: currentOtelContext())
      .end();

  span.end();
}
