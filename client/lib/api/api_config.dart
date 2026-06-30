import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API + auth config. Adjust BACKEND_URL for production builds.
class ApiConfig {
  ApiConfig._();

  /// Production backend. Override with --dart-define=TWENDE_BACKEND_URL=...
  /// for local development.
  static const String _productionUrl =
      'https://api.travelengine.zhio.dev/api/v1';

  static String get backendBaseUrl {
    const override = String.fromEnvironment('TWENDE_BACKEND_URL');
    if (override.isNotEmpty) return override;
    return _productionUrl;
  }

  /// Base-IdP issuer.
  static String get idpIssuer {
    const override = String.fromEnvironment('TWENDE_IDP_ISSUER');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String idpClientId = String.fromEnvironment(
    'TWENDE_IDP_CLIENT_ID',
    defaultValue: 'sq_live_twende_1b1i4f6j',
  );

  /// Mobile redirect — must match the registered redirect_uri at the IdP.
  static const String mobileRedirectUri = 'twende://auth/callback';
  static const String mobileRedirectScheme = 'twende';

  /// When true, the app bypasses IdP/login and uses a local "preview" session
  /// so the design/flow can be reviewed without a working auth server.
  /// Toggle with `--dart-define=DEV_BYPASS_AUTH=true` or leave on for dev.
  static const bool devBypassAuth = bool.fromEnvironment(
    'DEV_BYPASS_AUTH',
    defaultValue: true,
  );
}
