import 'dart:async';
import 'data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'toit_api_bridge.dart';
import 'igui_adapter.dart';

Map<String, String> dataMap = <String, String>{};
Map<String, String> receivedData = <String, String>{};

var mainTopicInp_ = 'cloud:demo/ping';
var mainTopicInpName_ = 'PING';
var mainTopicOut_ = 'cloud:demo/pong';
var mainTopicOutName_ = 'PONG';
var accessToken_ = '';

// const int cycles = 100;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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

class _MyHomePageState extends State<MyHomePage> implements IGUIAdapter {
  TextStyle style = const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final PageController pagerController =
      PageController(initialPage: 0, keepPage: false);

  var _email;
  var _password;
  var bridge_;

  bool _visibility = false;
  bool _loggedIn = false;

  bool measurementInProgress_ = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    pagerController.dispose();
    passwordTextController.dispose();
    emailTextController.dispose();
    //_timer.cancel();
    super.dispose();
  }

  // var _timer;
  // int _start = cycles;
  //
  // void startTimer() {
  //   const oneSec = Duration(milliseconds: 250);
  //   _timer = Timer.periodic(
  //     oneSec,
  //         (Timer timer) {
  //       if (_start == 0) {
  //         setState(() {
  //           timer.cancel();
  //           _start = cycles;
  //           measurementInProgress_ = false;
  //         });
  //       } else {
  //         setState(() {
  //            _start--;
  //           //updateDataMap();
  //           updateReceivedData();
  //         });
  //       }
  //     },
  //   );
  // }

  @override
  void onLogin() {
    setState(() {
      SystemChannels.textInput.invokeMethod('TextInput.hide'); // hide keyboard.
      _visibility = true;
      bridge_ = ToitBridge(this, mainTopicInpName_, mainTopicInp_, mainTopicOutName_, mainTopicOut_);
      bridge_.login(_email, _password, context);
    });
  }

  @override
  void onStop() {
    setState(() {
      _visibility = false;
    });
  }

  @override
  void onLogged() {
    setState(() {
      _loggedIn = true;
      emailTextController.text = '';
      passwordTextController.text = '';
      bridge_.create();
      pagerController.jumpToPage(1);
    });
  }

  void _onSend() {
    setState(() {
      SystemChannels.textInput.invokeMethod('TextInput.hide');  // hide keyboard.
      send("getData");
    });
  }

  @override
  void onReceive(var message) {
    setState(() {
      _visibility = false;
      print ("OnReceive->[$message]");
      updateReceivedMessage(message);
    });
  }

  void updateReceivedMessage(String receivedMessage) {
    DataModel data = extractData(receivedMessage);
    if (data.id == "e") {
      setState(() {
        measurementInProgress_ = false;
      });
      return;
    }

    receivedData[data.id] = data.value;

    String t1 = receivedData.containsKey("t1") ? receivedData["t1"].toString() : "--";
    String t2 = receivedData.containsKey("t2") ? receivedData["t2"].toString() : "--";
    String t3 = receivedData.containsKey("t3") ? receivedData["t3"].toString() : "--";
    String t4 = receivedData.containsKey("t4") ? receivedData["t4"].toString() : "--";
    String t5 = receivedData.containsKey("t5") ? receivedData["t5"].toString() : "--";

    dataMap["Blood Pressure"] = t1 + "/" + t2 + " mmHg";
    dataMap["Oxygen"]         = t3 + " %";
    dataMap["Temperature"]    = t4 + " °C";
    dataMap["Heart Rate"]     = t5 + " bpm"; //"97.6 bpm";
  }

  @override
  void onError(var message) {
    _showToast(context, message);
  }

  bool onBack() {
    return true;
  }

  void send(var message) async {
    await bridge_.send(message);
  }

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(label: 'CLOSE', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    updateDataMap();
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    final emailField = TextField(
      obscureText: false, // true
      style: style,
      controller: emailTextController,
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          hintText: _loggedIn ? "Send message" : "Email",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );

    final passwordField = TextField(
      obscureText: _loggedIn ? false : true,
      style: style,
      controller: passwordTextController,
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
          hintText: _loggedIn ? "Receive message" : "Password",
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );

    final loginButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: const Color(0xff01A0C7),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
        onPressed: () {
          _email = emailTextController.text;
          _password = passwordTextController.text;
          if (!_loggedIn) {
            if (_email.toString().isNotEmpty &&
                _password.toString().isNotEmpty) {
              onLogin();
            } else {
              _showToast(context, 'Enter e-mail and password please');
            }
          }
        },
        child: Text(!_loggedIn ? "Login" : "Send",
            textAlign: TextAlign.center,
            style: style.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

    final requestButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: const Color(0xff01A0C7),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
        onPressed: () {
          if (!measurementInProgress_) {
            setState(() {
              measurementInProgress_ = true;
              //@startTimer();
              _onSend();
            });
          }
        },
        child: Text(!measurementInProgress_ ? "Request Measurement" : "Measurement in Progress",
            textAlign: TextAlign.center,
            style: style.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    final buttonStyle = ButtonStyle(
        padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(15)),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: const BorderSide(color: Colors.blueAccent)
            )
        )
    );
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Container loginPage = Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 24.0),
                SizedBox(
                  height: 128.0,
                  child: Image.asset(
                    "assets/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32.0),
                emailField,
                const SizedBox(height: 24.0),
                passwordField,
                const SizedBox(
                  height: 24.0,
                ),
                loginButton,
                const SizedBox(
                  height: 16.0,
                ),
                CircularProgressIndicator(
                  backgroundColor:
                      _visibility ? Colors.blueAccent : Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                      _visibility ? Colors.blueGrey : Colors.transparent),
                  strokeWidth: 10,
                ),
              ],
            ),
          ),
        ));

    Container dataPage = Container(
      padding: const EdgeInsets.all(36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 24.0),
          SizedBox(
            height: 128.0,
            child: Image.asset(
              "assets/logo.png",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32.0),
          requestButton,
          const SizedBox(height: 16.0),
         CircularProgressIndicator(
            backgroundColor:
                measurementInProgress_ ? Colors.blueAccent : Colors.transparent,
            valueColor: AlwaysStoppedAnimation(
                measurementInProgress_ ? Colors.blueGrey : Colors.transparent),
            strokeWidth: 10,
          ),
          Expanded(
              child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            children:
              ListTile.divideTiles(
                context: context,
                  tiles: extractTiles(),
                  color: Colors.blueGrey,
            ).toList(),
          )),
        ],
      ),
    );

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Future<bool> _onBackPressed() async {
      //return true;
      print('_onBackPressed');
      bool rc = onBack();
      if (!rc) {
        return rc;
      } else {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an application'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0))),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
                style: buttonStyle,
              ),
              TextButton(
                onPressed: () {
                  if (bridge_ != null) {
                    bridge_.shutdown();
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('Yes'),
                style: buttonStyle,
              ),
            ],
          ),
        )) ?? false;
      }
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    return WillPopScope(

    child: Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pagerController,
        children: <Widget>[
          loginPage,
          dataPage,
          Container(
            color: Colors.green,
            child: Center(
                child: TextButton(
              onPressed: () {
                pagerController.jumpToPage(0);
              },
              child: const Text(
                'Page 3',
                style: TextStyle(color: Colors.white),
              ),
            )),
          ),
        ],
      ),
    ),
    onWillPop:
      _onBackPressed,
    );
  }

  List<Widget> extractTiles() {
    final List<String> elements = [
      "Blood Pressure",
      "Oxygen",
      "Temperature",
      "Heart Rate"
    ];
    List<Widget> list = List.generate(elements.length, (index) {
      String value = extractValue(elements[index]);
      return ListTile(
        title: Text(elements[index]),
        trailing: Text(value),
      );
    });
    return list;
  }
}

String extractValue(String element) {
  return dataMap[element].toString();
}

void updateDataMap() {

  String t1 = receivedData.containsKey("t1") ? receivedData["t1"].toString() : "--";
  String t2 = receivedData.containsKey("t2") ? receivedData["t2"].toString() : "--";
  String t3 = receivedData.containsKey("t3") ? receivedData["t3"].toString() : "--";
  String t4 = receivedData.containsKey("t4") ? receivedData["t4"].toString() : "--";
  String t5 = receivedData.containsKey("t5") ? receivedData["t5"].toString() : "--";

  dataMap["Blood Pressure"] = t1 + "/" + t2 + " mmHg";
  dataMap["Oxygen"]         = t3 + " %";
  dataMap["Temperature"]    = t4 + " °C";
  dataMap["Heart Rate"]     = t5 + " bpm"; //"97.6 bpm";

}

// String generateData(String key, String value) {
//   DataModel dm = DataModel(id: key, value: value);
//   return json.encode(dm);;
// }

DataModel extractData(String jsonText) {
  return DataModel.fromJson(jsonText);
}

// void updateReceivedMessage(String receivedMessage) {
//
//   DataModel data = extractData(receivedMessage);
//   if (data.id == "e") {
//     setState(() {
//       timer.cancel();
//       _start = cycles;
//       measurementInProgress_ = false;
//     });
//     return;
//   }
//
//   receivedData[data.id] = data.value;
//
//   String t1 = receivedData.containsKey("t1") ? receivedData["t1"].toString() : "--";
//   String t2 = receivedData.containsKey("t2") ? receivedData["t2"].toString() : "--";
//   String t3 = receivedData.containsKey("t3") ? receivedData["t3"].toString() : "--";
//   String t4 = receivedData.containsKey("t4") ? receivedData["t4"].toString() : "--";
//   String t5 = receivedData.containsKey("t5") ? receivedData["t5"].toString() : "--";
//
//   dataMap["Blood Pressure"] = t1 + "/" + t2 + " mmHg";
//   dataMap["Oxygen"]         = t3 + " %";
//   dataMap["Temperature"]    = t4 + " °C";
//   dataMap["Heart Rate"]     = t5 + " bpm"; //"97.6 bpm";
// }

// void updateReceivedData() {
//   Random random = Random();
//   int number = random.nextInt(12);
//   String receivedMessage = "";
//   if (number <= 2) {
//     receivedMessage = generateData("t1", (90 + random.nextInt(30)).toString());
//   }
//   else
//   if (number <= 4) {
//     receivedMessage = generateData("t2", (70 + random.nextInt(20)).toString());
//   }
//   else
//   if (number <= 6) {
//     receivedMessage = generateData("t3", (90 + random.nextInt(10)).toString());
//   }
//   else
//   if (number <= 8) {
//     receivedMessage = generateData("t4", (34 + random.nextInt(8)).toString());
//   }
//   else
//   if (number <= 11) {
//     receivedMessage = generateData("t5", (89 + random.nextInt(10)).toString());
//   }
//
//   DataModel data = extractData(receivedMessage);
//   receivedData[data.id] = data.value;
//
//   String t1 = receivedData.containsKey("t1") ? receivedData["t1"].toString() : "--";
//   String t2 = receivedData.containsKey("t2") ? receivedData["t2"].toString() : "--";
//   String t3 = receivedData.containsKey("t3") ? receivedData["t3"].toString() : "--";
//   String t4 = receivedData.containsKey("t4") ? receivedData["t4"].toString() : "--";
//   String t5 = receivedData.containsKey("t5") ? receivedData["t5"].toString() : "--";
//
//   dataMap["Blood Pressure"] = t1 + "/" + t2 + " mmHg";
//   dataMap["Oxygen"]         = t3 + " %";
//   dataMap["Temperature"]    = t4 + " °C";
//   dataMap["Heart Rate"]     = t5 + " bpm"; //"97.6 bpm";
// }

// void updateReceivedData() {
//   Random random = Random();
//   int number = random.nextInt(11);
//   if (number <= 2) {
//     receivedData["t1"] = (90 + random.nextInt(30)).toString();
//   }
//   else
//   if (number <= 4) {
//     receivedData["t2"] = (70 + random.nextInt(20)).toString();
//   }
//   else
//   if (number <= 6) {
//     receivedData["t3"] = (90 + random.nextInt(10)).toString();
//   }
//   else
//   if (number <= 8) {
//     receivedData["t4"] = (34 + random.nextInt(8)).toString();
//   }
//   else
//   if (number <= 10) {
//     receivedData["t5"] = (89 + random.nextInt(10)).toString();
//   }
//
//   String t1 = receivedData.containsKey("t1") ? receivedData["t1"].toString() : "--";
//   String t2 = receivedData.containsKey("t2") ? receivedData["t2"].toString() : "--";
//   String t3 = receivedData.containsKey("t3") ? receivedData["t3"].toString() : "--";
//   String t4 = receivedData.containsKey("t4") ? receivedData["t4"].toString() : "--";
//   String t5 = receivedData.containsKey("t5") ? receivedData["t5"].toString() : "--";
//
//   dataMap["Blood Pressure"] = t1 + "/" + t2 + " mmHg";
//   dataMap["Oxygen"]         = t3 + " %";
//   dataMap["Temperature"]    = t4 + " °C";
//   dataMap["Heart Rate"]     = t5 + " bpm"; //"97.6 bpm";
// }

