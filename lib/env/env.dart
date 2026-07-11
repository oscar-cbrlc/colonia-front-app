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
}