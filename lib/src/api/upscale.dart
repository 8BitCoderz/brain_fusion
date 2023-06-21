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
    // Use the custom HTTP client
    final client = createHttpClientWithDisabledCertificateCheck();

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..headers.addAll({
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
      })
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageData,
      ))
      ..fields['scale'] = scale.toString();

    // Use the custom client to send the request
    final response = await http.Response.fromStream(await client.send(request));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to upscale image');
    }
  }
}
