// Stub implementation for web builds where dart:io is unavailable.
// Only used to satisfy the type system for code paths that are not executed on web.

class File {
  final String path;
  File(this.path);
}
