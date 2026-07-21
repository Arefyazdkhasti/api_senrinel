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
      headers.putIfAbsent(HttpHeaders.hostHeader, () => _hostHeader(options.uri));
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
      if (options.data is FormData) {
        _writeFormData(buffer, options.data as FormData);
      } else {
        final body = _encodeBody(options.data);
        buffer.write(" --data '${_escapeShell(body)}'");
      }
    }

    buffer.write(" '${options.uri}'");
    return buffer.toString();
  }

  /// Host header value, including port when non-default for the scheme.
  static String _hostHeader(Uri uri) {
    final isDefaultPort =
        (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);
    return isDefaultPort ? uri.host : '${uri.host}:${uri.port}';
  }

  /// Emits `-F` flags for multipart fields and file placeholders.
  static void _writeFormData(StringBuffer buffer, FormData data) {
    for (final field in data.fields) {
      buffer.write(
        " -F '${_escapeShell(field.key)}=${_escapeShell(field.value)}'",
      );
    }
    for (final file in data.files) {
      final filename = file.value.filename ?? 'file';
      buffer.write(
        " -F '${_escapeShell(file.key)}=@${_escapeShell(filename)}'",
      );
    }
  }

  static String _encodeBody(dynamic data) {
    if (data is String) return data;
    return jsonEncode(data);
  }

  static String _escapeShell(String value) => value.replaceAll("'", "'\\''");
}
