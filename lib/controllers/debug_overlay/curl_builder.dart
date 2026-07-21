import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Builds a curl command from [RequestOptions].
///
/// Call this from an [HttpClientAdapter], not from an interceptor's
/// [Interceptor.onRequest]: by adapter time Dio has already applied
/// interceptor headers (cookies, auth) and computed `content-length`.
class CurlBuilder {
  CurlBuilder._();

  static const extraKey = 'debug_curl';

  static String fromRequestOptions(RequestOptions options) {
    final buffer = StringBuffer('curl -X ${options.method}');

    final headers = <String, dynamic>{...options.headers};

    final contentType = options.contentType;
    if (contentType != null &&
        !headers.keys.any(
          (k) => k.toLowerCase() == Headers.contentTypeHeader,
        )) {
      headers[Headers.contentTypeHeader] = contentType;
    }

    // Dart HttpClient defaults — never present on RequestOptions.
    // Only added on native (dart:io); browsers set their own.
    if (!kIsWeb) {
      headers.putIfAbsent(
        HttpHeaders.userAgentHeader,
        () => 'Dart/${Platform.version.split(' ').first} (dart:io)',
      );
      headers.putIfAbsent(HttpHeaders.acceptEncodingHeader, () => 'gzip');
      headers.putIfAbsent(HttpHeaders.hostHeader, () => options.uri.host);
    }

    headers.forEach((key, value) {
      if (value == null) return;
      // Dio may store multi-value headers (e.g. Cookie) as a List.
      final headerValue = value is Iterable
          ? value.map((e) => e.toString()).join('; ')
          : value.toString();
      buffer.write(
        " -H '${_escapeShell(key)}: ${_escapeShell(headerValue)}'",
      );
    });

    if (options.data != null) {
      final body = _encodeBody(options.data);
      buffer.write(" --data '${_escapeShell(body)}'");
    }

    buffer.write(" '${options.uri}'");
    return buffer.toString();
  }

  static String _encodeBody(dynamic data) {
    if (data is String) return data;
    if (data is FormData) {
      return data.fields.map((e) => '${e.key}=${e.value}').join('&');
    }
    return jsonEncode(data);
  }

  static String _escapeShell(String value) => value.replaceAll("'", "'\\''");
}
