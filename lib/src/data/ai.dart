import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../api/entities.dart';
import '../api/check_queue.dart';
import '../api/run.dart';
import '../api/status.dart';
import 'enums.dart';
import 'webkit_generator.dart';

import 'dart:io';
import 'package:http/io_client.dart';

http.Client createHttpClientWithDisabledCertificateCheck() {
  final httpClient = HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
  return IOClient(httpClient);
}

class CancellationToken {
  bool _isCanceled = false;

  void cancel() {
    _isCanceled = true;
  }

  void reset() {
    _isCanceled = false;
  }

  bool get isCanceled => _isCanceled;
}

class AI {
  late http.Client _client;
  late WebKit _webKit;
  late CheckQueue _checkQueue;
  late Run _run;
  late Status _status;
  late Entities _entities;

  AI() {
    _webKit = WebKit();
  }

  Future<Uint8List> runAI(
    String query,
    AIStyle style,
    CancellationToken cancellationToken,
  ) async {
    try {
      // _client = http.Client();
      _client = createHttpClientWithDisabledCertificateCheck();
      _checkQueue = CheckQueue(client: _client);

      final bool checker = await _checkQueue.checkQueue();
      if (checker) {
        _run = Run(
          client: _client,
          webKit: _webKit.generateBoundaryString(),
        );

        await _run.run(query, style);
        bool isSuccess = _run.success;
        String pocketId = _run.pocketId;
        if (isSuccess) {
          String result = '';

          _status = Status(client: _client);

          while (result != 'SUCCESS') {
            if (cancellationToken.isCanceled) {
              _client.close();
              throw Exception('AI process canceled');
            }

            await Future.delayed(const Duration(milliseconds: 200));
            await _status.getStatus(pocketId);
            result = _status.result;
          }
          if (result == 'SUCCESS') {
            await _status.getStatus(pocketId);
            bool isLoaded = _status.success;
            if (isLoaded) {
              _entities = Entities(client: _client);

              final image = await _entities.getEntities(pocketId);

              return image;
            } else {
              _client.close();
              throw Exception('Failed to get status (2) from AI');
            }
          } else {
            _client.close();
            throw Exception('Failed to get status (1) from AI');
          }
        } else {
          _client.close();
          throw Exception('Failed to run AI');
        }
      } else {
        _client.close();
        throw Exception('Failed to check queue in AI');
      }
    } catch (e) {
      _client.close();
      throw Exception('Error from AI package: $e');
    }
  }
}
