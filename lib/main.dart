import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(
    MaterialApp(
        home: MyApp(),
    )
);

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _fcm = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationAppLaunchDetails notificationAppLaunchDetails;
  StreamSubscription iosSubscription;

  @override
  void initState() {
      super.initState();

      _initFlutterNotificationPlugin();

      _fcm.configure(
        onMessage: (Map<String, dynamic> message) async{
          // fires when the app is open and running in the foreground.
          print("onMessage: $message");
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: ListTile(
                title: Text(message['notification']['title']),
                subtitle: Text(message['notification']['body']),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('Ok'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
        onLaunch: (Map<String, dynamic> message) async {
          // fires if the app is fully terminated.
          print("onLaunch: $message");
        },
        onResume: (Map<String, dynamic> message) async {
          // fires if the app is closed, but still running in the background.
          print("onResume: $message");
        },
      );

      if(Platform.isIOS){
        iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
          // save the token  OR subscribe to a topic here
          print(data.toString());
        });
      }
  }

  @override
  void dispose() {
    super.dispose();
    iosSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Notifications'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PaddedButton(
            text: 'Show Plain Notification',
            onPress: () async{
              await _showPlainNotification();
            },
          ),
          PaddedButton(
            text: "Schedule Notification after 5 Seconds",
            onPress: () async{
              await _showScheduledNotification();
            },
          ),
          PaddedButton(
            text: "Repeat Notification every 1 minute",
            onPress: () async{
              await _showRepeatedNotification();
            },
          ),
          FlatButton(
            child: Text('Cancel Repeating Notification'),
            onPressed: () async{
              await flutterLocalNotificationsPlugin.cancelAll();
            },
          )
        ],
      ),
    );
  }

  _initFlutterNotificationPlugin() async{
    notificationAppLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
    );
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  _showPlainNotification() async{
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel id', 'channel name', 'channel description', importance: Importance.Max, priority: Priority.High, ticker: 'ticker'
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  _showScheduledNotification() async{
    var scheduledNotificationDateTime = DateTime.now().add(Duration(seconds: 5));

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'scheduled channel id',
        'scheduled channel name',
        'scheduled channel description',
        icon: 'app_icon',
        enableLights: true,
        color: const Color.fromARGB(255, 255, 0, 0),
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
        1,
        'scheduled title',
        'scheduled body',
        scheduledNotificationDateTime,
        platformChannelSpecifics);

  }

  _showRepeatedNotification() async{
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'repeating channel id',
        'repeating channel name',
        'repeating channel description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(2, 'repeating title',
        'repeating body', RepeatInterval.EveryMinute, platformChannelSpecifics);
  }
}

class PaddedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPress;

  PaddedButton({@required this.text, @required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
      child: MaterialButton(
        child: Text(text, style: TextStyle(color: Colors.white),),
        color: Theme.of(context).accentColor,
        onPressed: onPress,
      ),
    );
  }
}
