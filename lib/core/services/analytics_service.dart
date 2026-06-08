// ignore_for_file: constant_identifier_names

import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Configuración de Google Analytics
  static const String GA4_PROPERTY_ID = '534492843';
  static const String WEB_STREAM_ID = '14591716390';

  /// Registra un evento personalizado
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      log('Error logging event: $e');
    }
  }

  /// Registra login de usuario
  static Future<void> logLogin({
    required String method,
    required String userId,
  }) async {
    try {
      await _analytics.logLogin(
        loginMethod: method, // 'email', 'google', etc.
      );
      await _analytics.setUserId(id: userId);
    } catch (e) {
      log('Error logging login: $e');
    }
  }

  /// Registra logout
  static Future<void> logLogout() async {
    try {
      await _analytics.setUserId(id: null);
      await logEvent(name: 'logout');
    } catch (e) {
      log('Error logging logout: $e');
    }
  }

  /// Establece propiedades del usuario
  static Future<void> setUserProperties({
    String? email,
    String? displayName,
    String? role,
  }) async {
    try {
      if (email != null) {
        await _analytics.setUserProperty(name: 'email', value: email);
      }
      if (displayName != null) {
        await _analytics.setUserProperty(
          name: 'display_name',
          value: displayName,
        );
      }
      if (role != null) {
        await _analytics.setUserProperty(name: 'user_role', value: role);
      }
    } catch (e) {
      log('Error setting user properties: $e');
    }
  }

  /// Registra una página visitada
  static Future<void> logPageView({
    required String pageName,
    String? pageClass,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'page_view',
        parameters: {
          'page_title': pageName,
          if (pageClass != null) 'page_class': pageClass,
        },
      );
    } catch (e) {
      log('Error logging page view: $e');
    }
  }

  /// Registra un error
  static Future<void> logError({
    required String description,
    String? fatal,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'error',
        parameters: {
          'description': description,
          if (fatal != null) 'fatal': fatal,
        },
      );
    } catch (e) {
      log('Error logging error event: $e');
    }
  }

  /// Registra búsqueda
  static Future<void> logSearch({required String searchTerm}) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
    } catch (e) {
      log('Error logging search: $e');
    }
  }

  /// Registra evento personalizado de acciones
  static Future<void> logAction({
    required String action,
    Map<String, Object>? details,
  }) async {
    try {
      await logEvent(name: action, parameters: details);
    } catch (e) {
      log('Error logging action: $e');
    }
  }

  /// Obtiene el instancia de Firebase Analytics (para uso avanzado)
  static FirebaseAnalytics get analytics => _analytics;
}
