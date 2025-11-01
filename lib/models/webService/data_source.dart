import 'package:api_sentinel/models/failure.dart';

import 'response_code.dart';
import 'response_message.dart';

enum DataSource {
  //for server timeout error
  connectTimeout,
  sendTimeout,
  receiveTimeout,

  //for server error response code
  badRequest,
  forbidden,
  unauthorized,
  notFound,
  internalServerError,

  //for cancel request by user
  cancel,

  //for server unknown error
  defaultError,
}

extension DataSourceExtension on DataSource {
  Failure getFailure() {
    switch (this) {
      //for server timeout error
      case DataSource.connectTimeout:
        return Failure(
          ResponseCode.connectTimeout,
          ResponseMessage.connectTimeout,
        );
      case DataSource.sendTimeout:
        return Failure(ResponseCode.sendTimeout, ResponseMessage.sendTimeout);
      case DataSource.receiveTimeout:
        return Failure(
          ResponseCode.receiveTimeout,
          ResponseMessage.receiveTimeout,
        );

      //for server error response code
      case DataSource.badRequest:
        return Failure(ResponseCode.badRequest, ResponseMessage.badRequest);
      case DataSource.forbidden:
        return Failure(ResponseCode.forbidden, ResponseMessage.forbidden);
      case DataSource.unauthorized:
        return Failure(ResponseCode.unauthorized, ResponseMessage.unauthorized);
      case DataSource.notFound:
        return Failure(ResponseCode.notFound, ResponseMessage.notFound);
      case DataSource.internalServerError:
        return Failure(
          ResponseCode.internalServerError,
          ResponseMessage.internalServerError,
        );

      //for cancel request by user
      case DataSource.cancel:
        return Failure(ResponseCode.cancel, ResponseMessage.cancel);

      //for server unknown error
      default:
        return Failure(ResponseCode.defaultError, ResponseMessage.defaultError);
    }
  }
}
