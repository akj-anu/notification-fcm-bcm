// import 'dart:developer';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_remote_config/firebase_remote_config.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Remote config',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: FutureBuilder<FirebaseRemoteConfig>(
//           future: setupRemoteConfig(),
//           builder: (context, snapshot) {
//             return snapshot.hasData

//                 ? Home(
//                     title: "REMOTE CONFIG",
//                     remoteConfig: snapshot.requireData,
//                   )
//                 : const Scaffold(
//                     body: Center(child: CircularProgressIndicator()),
//                   );
//           },
//         ));
//   }
// }

// class Home extends AnimatedWidget {

//   const Home({Key? key, required this.title, required this.remoteConfig})
//       : super(
//           key: key,
//           listenable: remoteConfig,
//         );

//   final String title;
//   final FirebaseRemoteConfig remoteConfig;

//   @override
//   Widget build(BuildContext context) {
//     var jsonlatest= remoteConfig.getString("json");
//     return Scaffold(
//       backgroundColor: Colors.blue,
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               jsonlatest,
//               style: Theme.of(context).textTheme.headline6,
//             ),
//             const SizedBox(
//               height: 30,
//             ),
//             Text(
//               remoteConfig.getString("ABCD"),
//               style: Theme.of(context).textTheme.headline6,
//             ),
//             const SizedBox(
//               height: 30,
//             ),
//             remoteConfig.getBool("updateAvailable")
//                 ? ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor:
//                           MaterialStateProperty.all<Color>(Colors.green),
//                     ),
//                     onPressed: () {},
//                     child: const Text("UPDATE"))
//                 : const SizedBox(),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//           elevation: 0.0,
//           onPressed: () async=> setupRemoteConfig(),
//           tooltip: 'nofication',
//           child: const Icon(Icons.refresh_outlined)),
//     );
//   }
// }

// Future<FirebaseRemoteConfig> setupRemoteConfig() async {
//   final FirebaseRemoteConfig remoteConfiguration = FirebaseRemoteConfig.instance;
//   log("on service ");
//   try {
//     await remoteConfiguration.setConfigSettings(RemoteConfigSettings(
//       fetchTimeout: const Duration(seconds: 10),
//       minimumFetchInterval: Duration.zero,
//     ));

//     await remoteConfiguration.fetchAndActivate();

//     log(remoteConfiguration.getString("ABCD"));
//     log(remoteConfiguration.getString("ABC"));
//     log(remoteConfiguration.getString("test"));

//   } catch (exception) {
//     log(exception.toString());
//   }
//   return remoteConfiguration;
// }

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    // 'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('A bg message just showed up :  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notification',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Notification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    this.title,
  }) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String noti = "No";
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: const Color.fromARGB(255, 234, 208, 10),
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
        setState(() {
          noti != notification.title!;
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title.toString()),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(notification.body.toString())],
                  ),
                ),
              );
            });
        setState(() {
          noti = notification.title!;
        });
      }
    });
  }

  void showNotification() {
    flutterLocalNotificationsPlugin.show(
        0,
        "Test title",
        "Notification Body",
        NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher')));
    setState(() {
      noti = "Test Notification";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Notification $noti',
            ),
            ElevatedButton(
                onPressed: () => showNotification(),
                child: const Text("Test Notification"))
          ],
        ),
      ),
    );
  }
}
