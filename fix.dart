import 'dart:io';

void main() {
  var dir = Directory('lib');
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var replaced = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
      if (content != replaced) {
        entity.writeAsStringSync(replaced);
      }
    }
  }
}
