// Opens SQLite databases on the running platform: files through FFI on
// Android/iOS/desktop, WebAssembly with IndexedDB storage on the web (PWA).
export 'sqlite_platform_io.dart' if (dart.library.js_interop) 'sqlite_platform_web.dart';
