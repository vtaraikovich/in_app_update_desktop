import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'application.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In App Update',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'In App Update'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  double downloadProgress = 0.0;
  bool isDownloading = false;
  String downloadedFilePath = '';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  void _clearCounter() {
    setState(() {
      _counter = 0;
    });
  }

  showUpdateDialog(Map<String, dynamic> versionJson) {
    final version = versionJson['version'];
    final updates = versionJson['description'] as List;
    return showDialog(
      context: context,
      builder: (contex) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(16.0),
          title: Text('Latest version is $version'),
          children: [
            Text('What\'s new in $version'),
            const SizedBox(height: 8.0),
            ...updates
                .map(
                  (e) => Row(
                    children: [
                      Container(
                        width: 4.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        '$e',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
            const SizedBox(height: 8.0),
            if (version > ApplicationConfig.currentVersion)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (Platform.isMacOS) {
                    downloadNewVersion(versionJson['macos_file_name']);
                  }
                  if (Platform.isWindows) {
                    downloadNewVersion(versionJson['windows_file_name']);
                  }
                },
                icon: const Icon(Icons.update),
                label: const Text('Update'),
              )
          ],
        );
      },
    );
  }

  Future<void> openExeFile(String filePath) async {
    await Process.start(filePath, ["-t", "-l", "1000"]).then((value) {});
  }

  Future<void> openDMGFile(String filePath) async {
    await Process.start(
        "MOUNTDEV=\$(hdiutil mount '$filePath' | awk '/dev.disk/{print\$1}')",
        []).then((value) {
      debugPrint("Value: $value");
    });
  }

  Future<void> _checkForUpdates() async {
    final jsonValue = await loadJsonFromGithub();
    debugPrint('Response: $jsonValue');
    showUpdateDialog(jsonValue);
  }

  Future<Map<String, dynamic>> loadJsonFromGithub() async {
    final response = await http.read(
      Uri.parse(
        'https://raw.githubusercontent.com/vtaraikovich/in_app_update_desktop/master/app_version_check/version.json',
      ),
    );
    return jsonDecode(response);
  }

  Future downloadNewVersion(String appPath) async {
    final fileName = appPath.split('/').last;
    isDownloading = true;
    setState(() {});

    final Dio dio = Dio();
    downloadedFilePath =
        "${(await getApplicationDocumentsDirectory()).path}/$fileName";

    await dio.download(
      'https://raw.githubusercontent.com/vtaraikovich/in_app_update_desktop/master/app_version_check/$appPath',
      downloadedFilePath,
      onReceiveProgress: (received, total) {
        final progress = (received / total) * 100;
        downloadProgress = double.parse(progress.toStringAsFixed(1));
        setState(() {});
      },
    );
    debugPrint("File Downloaded Path: $downloadedFilePath");
    if (Platform.isWindows) {
      await openExeFile(downloadedFilePath);
    }
    isDownloading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[700],
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Text(
                  'Current version is ${ApplicationConfig.currentVersion}',
                ),
              ),
              const SizedBox(width: 8.0),
              TextButton(
                onPressed: _checkForUpdates,
                child: const Text('Check updates'),
              ),
            ],
          ),
          if (isDownloading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(width: 8.0),
                Text('${downloadProgress.toStringAsFixed(1)} %'),
              ],
            ),
          Row(
            children: [
              FloatingActionButton(
                backgroundColor: Colors.purple[700],
                onPressed: _decrementCounter,
                tooltip: 'Decrement',
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8.0),
              FloatingActionButton(
                backgroundColor: Colors.purple[700],
                onPressed: _clearCounter,
                tooltip: 'Clear',
                child: const Icon(Icons.clear),
              ),
              const SizedBox(width: 8.0),
              FloatingActionButton(
                backgroundColor: Colors.purple[700],
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
