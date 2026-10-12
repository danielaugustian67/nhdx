import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Fixed namespace of the app for UUIDv5 ids. Never change it: ids of rows
/// already in the cloud are derived from it (PRD §8).
const appNamespace = '6f1c2b8e-4a7d-5c3e-9b21-0d4e8f7a6c51';

/// Deterministic id for a row with a natural key, e.g. `bookmark:1358280`.
/// The same item gets the same id on every device, so offline creates on two
/// devices end up as one row after sync.
String naturalId(String key) => _uuid.v5(appNamespace, key);

/// Random id for append-only rows and the device id.
String randomId() => _uuid.v4();
