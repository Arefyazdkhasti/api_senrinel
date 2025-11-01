import 'package:dio/dio.dart';

import '../../models/failure.dart';
import '../../models/webService/data_source.dart';
import '../../models/webService/response_code.dart';

class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      // dio error so its an error from response of the API or from dio itself
      failure = _handleError(error);
    } else {
      // default error
      failure = DataSource.defaultError.getFailure();
    }
  }
}

String handleErrorMessage(dynamic e, {String key = 'error_messages'}) {
  if (e is DioException) {
    try {
      //if the response data is null, return the default error message
      if (e.response?.data == null ||
          e.response?.data == "" ||
          e.response?.data is! Map) {
        return ErrorHandler.handle(e).failure.message;
      }

      if (e.response?.data[key] is String) {
        //if the response data is a string, return it
        return e.response?.data[key];
      } else if (e.response?.data[key] is List) {
        //if the response data is a list, return the first item as string
        return e.response?.data[key].first as String;
      } else {
        //if the response data is not a string or list, return the default error message
        return ErrorHandler.handle(e).failure.message;
      }
    } catch (e) {
      return ErrorHandler.handle(e).failure.message;
    }
  } else {
    return ErrorHandler.handle(e).failure.message;
  }
}

Failure _handleError(DioException error) {
  switch (error.type) {
    //for server timeout error
    case DioExceptionType.connectionTimeout:
      return DataSource.connectTimeout.getFailure();
    case DioExceptionType.sendTimeout:
      return DataSource.sendTimeout.getFailure();
    case DioExceptionType.receiveTimeout:
      return DataSource.receiveTimeout.getFailure();

    //for server error response code
    case DioExceptionType.badResponse:
      int? code = error.response?.statusCode;
      if (code != null) {
        switch (code) {
          case ResponseCode.badRequest:
            return DataSource.badRequest.getFailure();

          case ResponseCode.forbidden:
            return DataSource.forbidden.getFailure();

          case ResponseCode.unauthorized:
            return DataSource.unauthorized.getFailure();

          case ResponseCode.notFound:
            return DataSource.notFound.getFailure();

          case ResponseCode.internalServerError:
            return DataSource.internalServerError.getFailure();
        }
      }
      return DataSource.defaultError.getFailure();

    //for cancel request by user
    case DioExceptionType.cancel:
      return DataSource.cancel.getFailure();

    //for server unknown error
    default:
      return DataSource.defaultError.getFailure();
  }
}
