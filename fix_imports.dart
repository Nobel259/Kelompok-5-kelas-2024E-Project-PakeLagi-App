import 'dart:io';

void main() {
  final libDir = Directory('lib');

  // Create a map of filename -> relative path from lib
  final Map<String, String> fileMap = {};
  for (var entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath = entity.path
          .replaceFirst('lib\\', '')
          .replaceAll('\\', '/');
      final fileName = entity.uri.pathSegments.last;
      fileMap[fileName] = relativePath;
    }
  }

  // Iterate over all files and replace imports
  for (var entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final currentFileRelativePath = entity.path
          .replaceFirst('lib\\', '')
          .replaceAll('\\', '/');
      final currentFileDepth = currentFileRelativePath.split('/').length - 1;

      String content = entity.readAsStringSync();
      bool changed = false;

      // Find all imports
      final importRegex = RegExp(r"import '([^']+)';");
      content = content.replaceAllMapped(importRegex, (match) {
        final importedPath = match.group(1)!;

        // Skip package imports
        if (importedPath.startsWith('package:')) {
          return match.group(0)!;
        }

        // Extract just the filename
        final importedFileName = importedPath.split('/').last;

        if (fileMap.containsKey(importedFileName)) {
          final targetRelativePath = fileMap[importedFileName]!;

          // Calculate relative path from current file to target file
          String newImportPath = '';
          if (currentFileDepth == 0) {
            newImportPath = targetRelativePath;
          } else {
            // Build relative path
            final upDirs = List.filled(currentFileDepth, '..').join('/');
            newImportPath = '$upDirs/$targetRelativePath';
          }

          if (importedPath != newImportPath) {
            changed = true;
            return "import '$newImportPath';";
          }
        }
        return match.group(0)!;
      });

      if (changed) {
        entity.writeAsStringSync(content);
        print('Updated imports in $currentFileRelativePath');
      }
    }
  }
}
