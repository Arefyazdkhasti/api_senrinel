import 'package:api_sentinel/controllers/api_service.dart';
import 'package:api_sentinel/global_configs.dart';
import 'package:api_sentinel/widgets/debug_overlay_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyExampleApp());
}

class MyExampleApp extends StatelessWidget {
  const MyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your Package Example',
      home: const ApiExamplePage(),
      // theme: ThemeData.dark(),
    );
  }
}

class ApiExamplePage extends StatefulWidget {
  const ApiExamplePage({super.key});
  @override
  State<ApiExamplePage> createState() => _ApiExamplePageState();
}

class _ApiExamplePageState extends State<ApiExamplePage> {
  String _output = '';

  @override
  void initState() {
    super.initState();
    // Initialize ApiService once with baseUrl
    ApiService.instance.init(baseUrl: 'https://jsonplaceholder.typicode.com');
  }

  void _callApi({
    required HttpMethod method,
    required String path,
    dynamic data,
  }) {
    ApiService.instance.request(
      method: method,
      url: path,
      data: data,
      onCatchDioException: (dioErr) {
        setState(() {
          _output =
              'DioException: ${dioErr.message}\n' +
              'Status: ${dioErr.response?.statusCode}\n' +
              'Data: ${dioErr.response?.data}';
        });
      },
      onCatchException: (e) {
        setState(() {
          _output = 'Exception: $e';
        });
      },
      onSuccess: (resp) {
        setState(() {
          _output = 'Success: ${resp.statusCode}\nData: ${resp.data}';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('API Example')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.blue,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('GET /posts/1'),
                        onPressed: () {
                          _callApi(method: HttpMethod.get, path: '/posts/1');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.green,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('POST /posts'),
                        onPressed: () {
                          _callApi(
                            method: HttpMethod.post,
                            path: '/posts',
                            data: {'title': 'foo', 'body': 'bar', 'userId': 1},
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.orange,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('PUT /posts/1'),
                        onPressed: () {
                          _callApi(
                            method: HttpMethod.put,
                            path: '/posts/1',
                            data: {
                              'id': 1,
                              'title': 'foo_updated',
                              'body': 'bar',
                              'userId': 1,
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.teal,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('PATCH /posts/1'),
                        onPressed: () {
                          _callApi(
                            method: HttpMethod.patch,
                            path: '/posts/1',
                            data: {'title': 'patched title'},
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.red,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('DELETE /posts/1'),
                        onPressed: () {
                          _callApi(method: HttpMethod.delete, path: '/posts/1');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: globalBorderRadius * 1.5,
                                ),
                              ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.grey,
                          ),
                          fixedSize: const WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        child: const Text('GET /invalid404'),
                        onPressed: () {
                          _callApi(
                            method: HttpMethod.get,
                            path: '/invalid_endpoint',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _output,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Your debug overlay button
        const DebugOverlayWidget(),
      ],
    );
  }
}
