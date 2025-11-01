class ResponseCode {
  //for server timeout error
  static const int connectTimeout = -1;
  static const int receiveTimeout = -2;
  static const int sendTimeout = -3;

  //for server error response code
  static const int badRequest = 400; // failure, API rejected request
  static const int forbidden = 403; //  failure, API rejected request
  static const int unauthorized = 401; // failure, user is not authorised
  static const int notFound = 404; // failure, not found
  static const int internalServerError = 500; // failure, crash in server side

  //for cancel request by user
  static const int cancel = -4;

  //for server unknown error
  static const int defaultError = -5;
}