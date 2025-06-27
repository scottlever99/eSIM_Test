import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:esim_installer_flutter/esim_installer_flutter.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? qrImageBytes;
  String? smdpAddress;
  String? activationToken;
  String status = '';

  Future<void> _fetchData() async {
    const url = 'https://esim-api.onrender.com/api/provision'; // replace with your API

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"transType": "validate"}), // example payload
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          smdpAddress = data['activationCode'].split(r'$')[1];   // e.g. rsp-3104.idemia.io
          activationToken = data['activationCode'].split(r'$')[2]; // e.g. RWCCN‑...
          qrImageBytes = base64Decode(data['qrImageBase64']);
        });
      } else {
        setState(() => status = 'Error ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<void> _installEsim() async {
    final support = await EsimInstallerFlutter().isSupportESim() ?? false;
    if (!support) {
      setState(() => status = 'eSIM not supported');
      return;
    }
    try {
      final result = await EsimInstallerFlutter().installESimProfile(
        smdpAddress: smdpAddress!,
        activationToken: activationToken!,
      );
      setState(() => status = 'Result: $result');
    } catch (e) {
      setState(() => status = 'Install error: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('eSIM Installer')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: _fetchData, child: const Text('Fetch QR & Code')),
            const SizedBox(height: 20),
            if (qrImageBytes != null) ...[
              Image.memory(qrImageBytes!, width: 250),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _installEsim, child: const Text('Install eSIM')),
            ],
            if (status.isNotEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(status)),
          ]),
        ),
      ),
    );
  }
}
