import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(
    path: '.env',
    obfuscate: true,
)
abstract class Env {
  @EnviedField(varName: 'API_URL', obfuscate: true)
  static final String apiUrl = _Env.apiUrl;

  @EnviedField(varName: 'API_KEY', obfuscate: true)
  static final String apiKey = _Env.apiKey;

  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true)
  static final String googleServerClientId = _Env.googleServerClientId;

  @EnviedField(varName: 'MAPBOX_ACCESS_TOKEN', obfuscate: true)
  static final String mapboxAccessToken = _Env.mapboxAccessToken;

  @EnviedField(varName: 'AWS_ACCESS', obfuscate: true)
  static final String awsAccess = _Env.awsAccess;

  @EnviedField(varName: 'AWS_SECRET', obfuscate: true)
  static final String awsSecret = _Env.awsSecret;

  @EnviedField(varName: 'USER_THUMBS_ENDPOINT', obfuscate: true)
  static final String userThumbsEndpoint = _Env.userThumbsEndpoint;

}