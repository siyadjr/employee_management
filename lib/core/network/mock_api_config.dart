enum MockNetworkScenario {
  normal,
  slowNetwork, // Latency / Timeout simulation
  serverError, // 500 internal server error
  duplicateAttendanceConflict, // 409 conflict
  leaveValidationFailure, // 422 rejected by backend
}

class MockApiConfig {
  static MockNetworkScenario scenario = MockNetworkScenario.normal;
  static int simulatedDelayMs = 400; // Realistic network roundtrip

  static void setScenario(MockNetworkScenario newScenario) {
    scenario = newScenario;
  }
}
