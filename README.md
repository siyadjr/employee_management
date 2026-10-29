# REBS HRMS — Offline-Capable Employee Workspace

A production-grade, offline-capable Flutter application built for REBS HRMS. The app enables employees to monitor their attendance, check in/out within a 200-metre office geofence, view elapsed work duration in real-time, apply for leaves with complete validation rules, and reliably synchronize events across intermittent network connections.

---

## 1. Architecture & State Management

The application adheres to **Clean Feature-First Architecture** with strict separation of Presentation, Business Logic / Providers, Repositories, and Network / Persistence layers:

```
lib/
├── core/
│   ├── constants/             # AppConstants, Geofence radius (200m), Storage Keys
│   ├── navigation/            # AppRouter & MainNavigationShell (Dashboard, Attendance, Leave, Configure)
│   ├── network/               # MockHttpClient (BaseClient), ApiService, MockApiConfig
│   ├── storage/               # LocalStorageService (SharedPreferences persistence)
│   ├── theme/                 # Material 3 executive theme
│   ├── utils/                 # LocationService (Haversine geofence & simulator)
│   └── widgets/               # ReviewerSettingsModal (Quick scenario controls)
└── features/
    ├── attendance/            # Geofenced check-in/out, SyncRepository, AttendanceProvider
    ├── dashboard/             # Profile, elapsed duration ticker, balances, history
    ├── employee/              # Preconfigured employee profile (Alex Mercer, EMP-1042)
    ├── leave/                 # Leave application, 5 validation rules, LeaveProvider
    └── settings/              # ConfigureScreen & WorkspaceConfigProvider (Lat, Lng, Shifts)
```

### State Management Justification: Provider
- **Provider (`ChangeNotifierProvider`)** was chosen for clean separation of business logic from UI build methods.
- Every major business concern (`DashboardProvider`, `AttendanceProvider`, `LeaveProvider`, `SyncRepository`) is an isolated, testable unit.
- All presentation files and extracted widgets strictly maintain under 200 lines per file.

---

## 2. Offline Storage & Synchronization Design

This addresses the main engineering challenge of the assignment:

### A. Idempotency & Event Identity
- Every check-in/out attendance event generated on the device is assigned a **UUID (`clientEventId`)**.
- The server stores processed event IDs in `processed_event_ids`.
- When an event is retried due to a timeout or client reconnection, the server recognizes the UUID and returns an idempotent `200 Synced` response without duplicating records or throwing 409 conflicts.

### B. Persistence Across App Termination
- Pending events are serialized to disk using `LocalStorageService` (`SharedPreferences`).
- When the app is terminated or killed and reopened, pending events are immediately reloaded into memory with status **Pending Sync**.

### C. Strict Chronological Ordering
- During synchronization, events in the queue are sorted chronologically by timestamp (`event.timestamp.compareTo`).
- The engine guarantees `checkIn` is dispatched and confirmed before `checkOut`.
- If an event fails due to a network timeout or 500 error, sequential batch execution stops, preserving order for subsequent attempts.

### D. Sync States
1. **Pending Sync**: Event recorded locally while offline; displayed with an amber badge and pending count.
2. **Synced**: Successfully acknowledged by the server; displayed with green badge.
3. **Rejected**: Rejected by the server (e.g. 409 duplicate or 400 invalid order); logged with the server error message.

---

## 3. Device-Side vs Server-Side Validation

While the Flutter application performs client-side validation to provide instant feedback and an optimal user experience, a production server **must repeat and enforce all checks**:

1. **GPS & Geolocation Spoofing**: Client-side GPS coordinates can be manipulated using mock location apps or jailbroken/rooted devices. The server must validate IP geolocation, cellular cell tower data, or require signed hardware attestations (e.g., Play Integrity API / DeviceCheck).
2. **Device Clock Tampering**: Users can alter device system time to fake attendance timestamps. The production server must stamp the record with the authoritative NTP/server timestamp upon receipt or verify signed client timestamps against bounded drift.
3. **Double Attendance & Race Conditions**: In high-concurrency environments or across multiple devices, only the server database can enforce atomic transactions and unique constraints for `(employee_id, date, event_type)`.
4. **Leave Balance Overdrafts**: Multiple simultaneous leave requests could pass client balance validation. The server must run atomic balance deduction within database transactions.

---

## 4. Reviewer Simulation Mode (Testing Scenarios)

The app includes built-in controls for reviewers to test all scenarios on real devices or emulators:

### Location Simulator (Geofence: 200m)
1. Tap the **Tune Icon (⚙️ / Controls)** in the top app bar of Dashboard or Attendance screen.
2. Under **Location Simulation Mode**, select:
   - **At Office (< 20m)**: Simulates employee directly inside HQ (< 20m from office coordinates). Check-in and check-out succeed.
   - **Outside (~350m)**: Simulates employee 350m away from office. Check-in/out is blocked with clear feedback.
   - **Device GPS**: Reads the actual physical device hardware GPS.

### Mock API Network Scenarios
In the same modal, switch **Mock API Network Condition** between:
- `Normal (200 OK)`: Standard fast responses.
- `Timeout / Slow Network`: Simulates network timeouts (> 3.5s latency).
- `Server Error (500)`: Simulates REBS server crashes.
- `Duplicate Conflict (409)`: Simulates existing attendance conflict.
- `Leave Validation Rejection (422)`: Simulates server-side leave policy rejection.

---

## 5. Automated Tests

Run the complete test suite:
```bash
flutter test
```

### Test Coverage Highlights:
- **`test/assignment_requirements_test.dart`**:
  1. Check-out without check-in is rejected.
  2. Repeated submission or retry does not create duplicate attendance (idempotency).
  3. Pending attendance survives persistence across app reload and syncs in sequential order.
  4. Overlapping leave dates are rejected across pending/approved leave requests.
- **`test/dashboard_widget_test.dart`**:
  - Validates dashboard rendering, employee profile header, leave balance cards, and sync badge.
- **`test/mock_api_test.dart`**:
  - Tests HTTP BaseClient contract, scenario switching, and status code handling.
