// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import '../../../../api.dart' as api;
import '../../../../sdk.dart' as sdk;

class BatchSpanProcessor implements sdk.SpanProcessor {
  static const int _DEFAULT_MAXIMUM_BATCH_SIZE = 512;
  static const int _DEFAULT_MAXIMUM_QUEUE_SIZE = 2048;
  static const int _DEFAULT_EXPORT_DELAY = 5000;

  final sdk.SpanExporter _exporter;
  final Logger _log = Logger('opentelemetry.BatchSpanProcessor');
  final int _maxExportBatchSize;
  final int _maxQueueSize;
  final int _scheduledDelayMillis;
  final List<sdk.ReadOnlySpan> _spanBuffer = [];

  bool _isShutdown = false;

  Timer? _timer;

  BatchSpanProcessor(this._exporter,
      {int maxExportBatchSize = _DEFAULT_MAXIMUM_BATCH_SIZE,
      int scheduledDelayMillis = _DEFAULT_EXPORT_DELAY})
      : _maxExportBatchSize = maxExportBatchSize,
        _maxQueueSize = _DEFAULT_MAXIMUM_QUEUE_SIZE,
        _scheduledDelayMillis = scheduledDelayMillis;

  @override
  void forceFlush() {
    if (_isShutdown) {
      return;
    }
    while (_spanBuffer.isNotEmpty) {
      _flushBatch();
    }
    _exporter.forceFlush();
  }

  @override
  void onEnd(sdk.ReadOnlySpan span) {
    if (_isShutdown) {
      return;
    }
    _addToBuffer(span);
  }

  @override
  void onStart(sdk.ReadWriteSpan span, api.Context parentContext) {}

  @override
  void shutdown() {
    forceFlush();
    _isShutdown = true;
    _clearTimer();
    _exporter.shutdown();
  }

  void _addToBuffer(sdk.ReadOnlySpan span) {
    if (_spanBuffer.length >= _maxQueueSize) {
      // Buffer is full, drop span.
      _log.warning(
          'Max queue size exceeded. Dropping ${_spanBuffer.length} spans.');
      return;
    }

    _spanBuffer.add(span);
    _startTimer();
  }

  void _startTimer() {
    if (_timer != null) {
      // _timer already defined.
      return;
    }

    _timer = Timer(Duration(milliseconds: _scheduledDelayMillis), () {
      _flushBatch();
      if (_spanBuffer.isNotEmpty) {
        _clearTimer();
        _startTimer();
      }
    });
  }

  void _clearTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _flushBatch() {
    _clearTimer();
    if (_spanBuffer.isEmpty) {
      return;
    }

    final batchSize = min(_spanBuffer.length, _maxExportBatchSize);
    final batch = _spanBuffer.sublist(0, batchSize);
    _spanBuffer.removeRange(0, batchSize);

    _exporter.export(batch);
  }
}
