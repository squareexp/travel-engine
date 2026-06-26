import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API + auth config. Adjust BACKEND_URL for production builds.
class ApiConfig {
  ApiConfig._();

  /// Twende backend, picked per-platform so the same dart build works on both
  /// iOS Simulator (uses host loopback) and Android Emulator (uses 10.0.2.2).
  static String get backendBaseUrl {
    const override = String.fromEnvironment('TWENDE_BACKEND_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8090/api/v1';
    }
    return 'http://localhost:8090/api/v1';
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
