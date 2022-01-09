import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterdrive/secureStorage.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

const _clientId =
    "1089696096924-j1ggdg4ond1th7r9a5lh3kv2cgnvnlmq.apps.googleusercontent.com";

const _scopes = [ga.DriveApi.driveFileScope];

class GoogleDrive {
  final storage = SecureStorage();
  final storag = FlutterSecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient =
          await clientViaUserConsent(ClientId(_clientId), _scopes, (url) {
        //Open Url in Browser
        launch(url);
      });
      //Save Credentials
      await storage.saveCredentials(authClient.credentials.accessToken,
          authClient.credentials.refreshToken);
      return authClient;
    } else {
      print(credentials["expiry"]);
      //Already authenticated
      return authenticatedClient(
          http.Client(),
          AccessCredentials(
              AccessToken(credentials["type"], credentials["data"],
                  DateTime.tryParse(credentials["expiry"])),
              credentials["refreshToken"],
              _scopes));
    }
  }

  //Upload File
  Future upload(File file) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    print("Uploading file");
    var response = await drive.files.create(
        ga.File()..name = p.basename(file.absolute.path),
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()));

    print("Result ${response.toJson()}");
  }

  Future<Map<String, dynamic>> getCredentials() async {
    var result = await storag.readAll();
    if (result.length == 0) return null;
    return result;
  }
}
