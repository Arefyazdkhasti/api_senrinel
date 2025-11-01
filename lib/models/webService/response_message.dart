import 'package:get/get.dart';

class ResponseMessage {
  //for server timeout error
  static String connectTimeout = 'timeout_error'.tr;
  static String receiveTimeout = 'timeout_error'.tr;
  static String sendTimeout = 'timeout_error'.tr;

  //for server error response code
  static String badRequest =
      'bad_request_error'.tr; // failure, API rejected request
  static String forbidden =
      'forbidden_error'.tr; //  failure, API rejected request
  static String unauthorized =
      'unauthorized_error'.tr; // failure, user is not authorized
  static String notFound =
      'not_found_error'.tr; // failure, crash in server side
  static String internalServerError =
      'internal_server_error'.tr; // failure, crash in server side

  //for cancel request by user
  static String cancel = 'default_error'.tr;

  //for server unknown error
  static String defaultError = 'default_error'.tr;
}
