/// An in-memory bank that speaks JSON through a dio interceptor, with
/// controls for demos. Never a dependency of the production app.
library;

export 'src/mock_bank_interceptor.dart';
export 'src/mock_bank_server.dart';
export 'src/models.dart' show ServerAccount;
export 'src/oauth.dart' show DemoUser;
