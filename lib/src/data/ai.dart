import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../api/entities.dart';
import '../api/check_queue.dart';
import '../api/run.dart';
import '../api/status.dart';
import 'webkit_generator.dart';

/// init this class in any Widget
/// to use the [runAI] function
class AI {
  late http.Client _client;
  late WebKit webKit;
  late CheckQueue checkQueue;
  late Run run;
  late Status status;
  late Entities entities;
  AI() {
    /// Initialize the client instance member
    _client = http.Client();

    /// Initialize the class
    webKit = WebKit();

    /// Initialize the classes with the client instance member
    checkQueue = CheckQueue(client: _client);

    /// Initialize the classes with the client instance member and pass the [generateBoundaryString] function
    run = Run(client: _client, webKit: webKit.generateBoundaryString());

    /// Initialize the classes with the client instance member
    status = Status(client: _client);

    /// Initialize the classes with the client instance member
    entities = Entities(client: _client);
  }

  /// Use this function to make the image .
  ///
  /// It required Two parameter the
  /// [query] an [AIStyle] .
  ///
  /// [query] is String text and
  /// [AIStyle] is a style of the image that you want.
  ///
  /// The [runAI] function return a [Uint8List]
  /// so it can be use in both dart and Flutter.
  Future<Uint8List> runAI(
    String query,
    AIStyle style,
  ) async {
    try {
      /// Run First Endpoint and Check
      final bool checker = await checkQueue.checkQueue();
      if (checker) {
        /// Run Second Endpoint
        await run.run(query, style);
        bool isSuccess = run.success;
        String pocketId = run.pocketId;
        if (isSuccess) {
          String result = 'PROCESSING';

          /// Run 3rd Endpoint
          while (result == 'PROCESSING') {
            await Future.delayed(const Duration(milliseconds: 500));
            await status.getStatus(pocketId);
            result = status.result;
          }
          if (result != 'PROCESSING') {
            await status.getStatus(pocketId);
            bool isLoaded = status.success;
            if (isLoaded) {
              /// Run 4th Endpoint
              final image = await entities.getEntities(pocketId);

              /// Run the Data
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

/// The [AIStyle] is enum for Famous Styles of Drawing
///
enum AIStyle {
  noStyle,
  anime,
  moreDetails,
  islamic,
  cyberPunk,
  kandinskyPainter,
  aivazovskyPainter,
  malevichPainter,
  picassoPainter,
  goncharovaPainter,
  classicism,
  renaissance,
  oilPainting,
  pencilDrawing,
  digitalPainting,
  medievalStyle,
  render3D,
  cartoon,
  studioPhoto,
  portraitPhoto,
  mosaic,
  iconography,
  khokhlomaPainter,
  christmas,
}
