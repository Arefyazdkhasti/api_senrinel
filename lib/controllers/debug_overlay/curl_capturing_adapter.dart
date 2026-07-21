import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'curl_builder.dart';

/// Wraps Dio's platform [HttpClientAdapter] and builds the final curl
/// right before the request is sent — the latest point where all Dio
/// headers (including `content-length`) are available.
class CurlCapturingAdapter implements HttpClientAdapter {
  CurlCapturingAdapter(this._inner);

  final HttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    options.extra[CurlBuilder.extraKey] = CurlBuilder.fromRequestOptions(
      options,
    );
    return _inner.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
