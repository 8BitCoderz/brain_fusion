import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:brain_fusion/src/data/strings.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class UpScale {
  static const String apiUrl = 'https://api2.pixelcut.app/image/upscale/v1';

  // Add this method to create an HTTP client with disabled certificate check
  http.Client createHttpClientWithDisabledCertificateCheck() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    return IOClient(httpClient);
  }

  Future<Uint8List> upscaleImage(Uint8List imageData, int scale) async {
    var headers = {
      'authority': 'api2.pixelcut.app',
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'en-US,en;q=0.9',
      'authorization': '',
      'origin': 'https://create.pixelcut.ai',
      'referer': 'https://create.pixelcut.ai/',
      'sec-ch-ua': secChUa,
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': 'macOS',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'cross-site',
      'user-agent': userAgent,
      'x-client-version': 'web',
    };

    if (imageData == null || imageData.isEmpty) {
      print("Image data is empty");
      return Uint8List(0); // Return an empty Uint8List instead of null
    }

    String boundary = 'wL36Yn8afVp8Ag7AmP8qZ0SA4n1v9T';
    headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';

    var dataList = <List<int>>[];
    dataList.add(utf8.encode('--$boundary\r\n'));
    dataList.add(utf8.encode(
        'Content-Disposition: form-data; name=image; filename=input_image.png\r\n'));
    dataList.add(utf8.encode('Content-Type: image/png\r\n\r\n'));
    dataList.add(imageData);
    dataList.add(utf8.encode('\r\n--$boundary\r\n'));
    dataList
        .add(utf8.encode('Content-Disposition: form-data; name=scale\r\n\r\n'));
    dataList.add(utf8.encode('$scale\r\n'));
    dataList.add(utf8.encode('--$boundary--\r\n'));

    Stream<List<int>> byteStream = Stream.fromIterable(dataList);
    int contentLength = dataList.fold<int>(0, (sum, list) => sum + list.length);

    http.StreamedRequest request = http.StreamedRequest(
        'POST', Uri.parse('https://api2.pixelcut.app/image/upscale/v1'));
    request.headers.addAll(headers);
    request.contentLength = contentLength;

    // Add the byte stream to the request sink and close it
    http.ByteStream(byteStream)
        .pipe(request.sink as StreamConsumer<List<int>>)
        .then((_) {
      request.sink.close();
    });

    // Use the custom HTTP client
    final client = createHttpClientWithDisabledCertificateCheck();

    http.StreamedResponse response = await client.send(request);

    if (response.statusCode == 200) {
      return await response.stream.toBytes();
    } else {
      print("Error: ${response.statusCode} ${response.reasonPhrase}");
      print("Response body: ${await response.stream.bytesToString()}");
      return Uint8List(0); // Return an empty Uint8List instead of null
    }
  }
}
