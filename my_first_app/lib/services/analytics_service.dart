import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analyticsOverride = analytics;

  final FirebaseAnalytics? _analyticsOverride;

  FirebaseAnalytics get _analytics =>
      _analyticsOverride ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin() {
    return _analytics.logLogin(loginMethod: 'email_password');
  }

  Future<void> logSignUp() {
    return _analytics.logSignUp(signUpMethod: 'email_password');
  }

  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  Future<void> logEvent(String eventName, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: eventName, parameters: parameters);
  }
}
