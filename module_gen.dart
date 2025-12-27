import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    // ignore: avoid_print
    print('Please provide a route name.');
    exit(1);
  }

  final routeName = arguments[0];
  final path = '/$routeName';

  final className =
      '${routeName[0].toUpperCase()}${routeName.substring(1)}Screen';

  // Create module folder structure and bloc files
  createModuleFolders(routeName);

  addRouteToAppRoutes(routeName, path);
  addRouteToAppPages(routeName, className);
  // ignore: avoid_print
  print('Route $routeName has been added successfully.');
}

void createModuleFolders(String moduleName) {
  final basePath = 'lib/modules/$moduleName';

  // List of directories to be created
  final directories = ['$basePath/bloc', '$basePath/data', '$basePath/screen'];

  for (final dir in directories) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      // ignore: avoid_print
      print('Created directory: $dir');
    } else {
      // ignore: avoid_print
      print('Directory already exists: $dir');
    }
  }

  // Create the screen file inside the screen folder
  createScreenFile(moduleName, basePath);

  // Create bloc files (bloc, event, state)
  createBlocFiles(moduleName, basePath);
}

void createScreenFile(String moduleName, String basePath) {
  final screenFile = File('$basePath/screen/${moduleName}_view.dart');
  if (!screenFile.existsSync()) {
    screenFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class ${moduleName[0].toUpperCase()}${moduleName.substring(1)}Screen extends StatelessWidget {
  const ${moduleName[0].toUpperCase()}${moduleName.substring(1)}Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${moduleName[0].toUpperCase()}${moduleName.substring(1)} Screen'),
      ),
      body: const Center(
        child: Text('Welcome to $moduleName screen!'),
      ),
    );
  }
}
''');
    // ignore: avoid_print
    print('Created screen file: ${moduleName}_view.dart');
  }
}

void createBlocFiles(String moduleName, String basePath) {
  final blocFile = File('$basePath/bloc/${moduleName}_bloc.dart');
  final eventFile = File('$basePath/bloc/${moduleName}_event.dart');
  final stateFile = File('$basePath/bloc/${moduleName}_state.dart');

  final classNamePrefix = moduleName[0].toUpperCase() + moduleName.substring(1);

  if (!blocFile.existsSync()) {
    blocFile.writeAsStringSync('''
import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/$moduleName/bloc/${moduleName}_event.dart';
import 'package:kids_learning/modules/$moduleName/bloc/${moduleName}_state.dart';

class ${classNamePrefix}Bloc extends Bloc<${classNamePrefix}Event, ${classNamePrefix}State> {
  ${classNamePrefix}Bloc() : super(${classNamePrefix}Initial()) {
    on<${classNamePrefix}Event>((event, emit) {
      // TODO: implement event handler
    });
  }
}
''');
    // ignore: avoid_print
    print('Created bloc file: ${moduleName}_bloc.dart');
  }

  if (!eventFile.existsSync()) {
    eventFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';

sealed class ${classNamePrefix}Event extends Equatable {
  const ${classNamePrefix}Event();

  @override
  List<Object> get props => [];
}
''');
    // ignore: avoid_print
    print('Created event file: ${moduleName}_event.dart');
  }

  if (!stateFile.existsSync()) {
    stateFile.writeAsStringSync('''
import 'package:equatable/equatable.dart';

sealed class ${classNamePrefix}State extends Equatable {
  const ${classNamePrefix}State();

  @override
  List<Object> get props => [];
}

final class ${classNamePrefix}Initial extends ${classNamePrefix}State {}
''');
    // ignore: avoid_print
    print('Created state file: ${moduleName}_state.dart');
  }
}

void addRouteToAppRoutes(String routeName, String path) {
  final routesFile = File('lib/routes/app_routes.dart');

  if (!routesFile.existsSync()) {
    // ignore: avoid_print
    print('app_routes.dart file not found.');
    exit(1);
  }

  final content = routesFile.readAsStringSync();

  final routesEntry = '''
  static const $routeName = _Paths.$routeName;''';
  final pathsEntry = '''
  static const $routeName = '$path';''';
  final namesEntry = '''
  static const $routeName = '$routeName';''';

  final namesPathEntry = '''
  static const $routeName = _Names.$routeName;''';

  final updatedContent = content
      .replaceFirst(
        'abstract class Routes {',
        'abstract class Routes {\n$routesEntry',
      )
      .replaceFirst(
        'abstract class _Paths {',
        'abstract class _Paths {\n$pathsEntry',
      )
      .replaceFirst(
        'abstract class _Names {',
        'abstract class _Names {\n$namesEntry',
      )
      .replaceFirst(
        'abstract class Names {',
        'abstract class Names {\n$namesPathEntry',
      );

  routesFile.writeAsStringSync(updatedContent);
}

void addRouteToAppPages(String routeName, String className) {
  final pagesFile = File('lib/routes/app_pages.dart');

  if (!pagesFile.existsSync()) {
    // ignore: avoid_print
    print('app_pages.dart file not found.');
    exit(1);
  }

  final content = pagesFile.readAsStringSync();

  final importEntry =
      "import 'package:kids_learning/modules/$routeName/screen/${routeName}_view.dart';\n";
  final routeEntry =
      '''
    GoRoute(
      name: Names.$routeName,
      path: Routes.$routeName,
      builder: (context, state) => const $className(),
    ),
''';

  final updatedContent =
      importEntry + content.replaceFirst('routes: [', 'routes: [\n$routeEntry');

  pagesFile.writeAsStringSync(updatedContent);
}
