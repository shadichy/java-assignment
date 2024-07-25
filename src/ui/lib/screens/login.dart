// import 'dart:convert';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assignment/provider/account.dart';
import 'package:assignment/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;

// import 'package:assignment/provider/constants.dart' as constants;
// import 'package:path_provider/path_provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String username = '';
  String password = '';
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<bool> tryFetch(int port, int trials) async {
    if (trials == 0) return false;
    try {
      await get(Uri.https("${Data().hostname}:$port"), headers: {
        "Authorization":
            'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      });
      return true;
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 1500));
      return await tryFetch(port, trials--);
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    var outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: c.outline),
    );
    return Scaffold(
      body: Center(
        child: Container(
          alignment: Alignment.center,
          width: 300,
          height: 200,
          child: Column(children: [
            const Text("Login"),
            const Divider(color: Colors.transparent, height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "account",
                border: outlineInputBorder,
              ),
              onChanged: (s) => username = s,
            ),
            const Divider(color: Colors.transparent, height: 8),
            TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: "password",
                border: outlineInputBorder,
              ),
              onChanged: (s) => password = s,
            ),
            const Divider(color: Colors.transparent, height: 8),
            TextButton(
              onPressed: () async {
                String stdErr = "";
                File port =
                    File("${(await getTemporaryDirectory()).path}/port.asn");
                int httpPort;
                int httpsPort;
                int pid = -1;
                if ((port.existsSync())) {
                  httpPort = int.parse(port.readAsStringSync());
                  httpsPort = httpPort + 1000;
                } else {
                  httpPort = Random().nextInt(6999) + 2000;
                  httpsPort = httpPort + 1000;
                  String jar =
                      "../../target/artifact-1.0-SNAPSHOT-jar-with-dependencies.jar";
                  // File authFile = File.fromUri(Uri.file(
                  //     "${await getTemporaryDirectory()}/${getRandomString(8)}.tmp"));
                  // await authFile.create();
                  // authFile.writeAsStringSync(
                  //     "assignment.user=${username.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}\nassignment.psk=${password.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}");
                  Process p = await Process.start("java", [
                    // "-Dassignment.authfile=${authFile.uri.toFilePath()}",
                    "-Dassignment.httpport=$httpPort",
                    "-Dassignment.httpsport=$httpsPort",
                    // "-Dassignment.dbname=AssignmentDiscDB",
                    // "-Dassignment.dbpasswordless=false",
                    "-jar",
                    jar
                  ]);
                  pid = p.pid;
                  p.exitCode.then((i) {
                    if (i == 0) return;
                  });
                  p.stdin.writeln(username);
                  p.stdin.writeln(password);
                  stderr.addStream(p.stderr);
                  stdout.addStream(p.stdout);
                }
                if (await tryFetch(httpsPort, 5)) {
                  Data().init(username, password, httpPort, pid);
                  Navigator.of( context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const Home(),
                  ));
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => AlertDialog(
                    content: Text(stdErr),
                    actions: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: const Text("OK"),
                      )
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: c.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: Text(
                "Login",
                style: t.bodyMedium?.apply(color: c.onPrimary),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
