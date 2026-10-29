import 'package:flutter/foundation.dart';

enum MockNetworkScenario {
  normal,
  slowNetwork, // Latency / Timeout simulation
  serverError, // 500 internal server error
  duplicateAttendanceConflict, // 409 conflict
  leaveValidationFailure, // 422 rejected by backend
}

class MockApiConfig {
  static final ValueNotifier<MockNetworkScenario> notifier =
      ValueNotifier<MockNetworkScenario>(MockNetworkScenario.normal);

  static MockNetworkScenario get scenario => notifier.value;

  static int simulatedDelayMs = 400; // Realistic network roundtrip

  static void setScenario(MockNetworkScenario newScenario) {
    if (notifier.value != newScenario) {
      notifier.value = newScenario;
    }
  }

  static String getScenarioTitle(MockNetworkScenario sc) {
    switch (sc) {
      case MockNetworkScenario.normal:
        return 'Normal (200 OK)';
      case MockNetworkScenario.slowNetwork:
        return 'Timeout / Slow Network';
      case MockNetworkScenario.serverError:
        return 'Server Error (500)';
      case MockNetworkScenario.duplicateAttendanceConflict:
        return 'Duplicate Attendance Conflict (409)';
      case MockNetworkScenario.leaveValidationFailure:
        return 'Leave Validation Rejection (422)';
    }
  }

  static String getScenarioDescription(MockNetworkScenario sc) {
    switch (sc) {
      case MockNetworkScenario.normal:
        return 'Requests succeed normally with 200 OK.';
      case MockNetworkScenario.slowNetwork:
        return 'Simulates slow responses and client timeouts (triggers offline queue).';
      case MockNetworkScenario.serverError:
        return 'Simulates 500 Internal Server Error response.';
      case MockNetworkScenario.duplicateAttendanceConflict:
        return 'Simulates 409 Conflict when record already exists on server.';
      case MockNetworkScenario.leaveValidationFailure:
        return 'Simulates 422 Unprocessable Entity rejecting leave application.';
    }
  }
}

