import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TextEditingController username = TextEditingController();
  TextEditingController body = TextEditingController();
  TextEditingController title = TextEditingController();
  String? mtoken = '';
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
    initInfo();
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    // var iOSInitialise = const IOSFlutterLocalNotificationsPlugin();
    var initializationSettings = InitializationSettings(
      android: androidInitialize,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        print('...........onMessage.........');
        print(
            'onMessage:${message.notification?.title}/${message.notification?.body}}');

        BigTextStyleInformation bigTextStyleInformation =
            BigTextStyleInformation(
          message.notification!.body.toString(),
          htmlFormatBigText: true,
          contentTitle: message.notification!.title.toString(),
          htmlFormatContentTitle: true,
        );
        AndroidNotificationDetails androidplatformChannelSpecifics =
            AndroidNotificationDetails(
          'fcm',
          'fcm',
          importance: Importance.high,
          styleInformation: bigTextStyleInformation,
          priority: Priority.high,
          playSound: true,
        );

        NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidplatformChannelSpecifics,
          // iOS: const IOSNotificationDetails(),
        );
        await flutterLocalNotificationsPlugin.show(
            0,
            message.notification?.title,
            message.notification?.body,
            platformChannelSpecifics,
            payload: message.data['body']);
      },
    );
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) => {
          setState(
            () {
              mtoken = token;
              print('My token is  $mtoken');
            },
          ),
          saveToken(token!),
        });
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance.collection('UserTokens').doc('User1').set({
      'token': token,
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User Granted Permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User Granted Provisional Permission');
    } else {
      print('User declined or has not accepted the  permission');
    }
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('http://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=	AAAAPh2IXxE:APA91bGE14KIs0NvYvF3rm8qoFY8TWjK99TmCzjxOMfc7qXrsfbuzzLCoSkPjlhewG1GpLDoiQjFim864rdMhx1qq21OHfeziaMnHGcz76xnFa0xKoKZ2TfWR8QVEdUL35iAlmLQKaTN'
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              'title': title,
              'body': body,
              'android_channel_id': 'dbfood',
            },
            'to': token,
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('error push notification');
      }
    }
  }

  @override
  void dispose() {
    username.dispose();
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: username,
            ),
            TextFormField(
              controller: title,
            ),
            TextFormField(
              controller: body,
            ),
            GestureDetector(
              onTap: () async {
                String name = username.text.trim();
                String titleText = title.text;
                String bodyText = body.text;

                if (name != '') {
                  DocumentSnapshot snap = await FirebaseFirestore.instance
                      .collection('UserToken')
                      .doc(name)
                      .get();
                  String token = snap['token'];

                  print(token);

                  sendPushMessage(token, titleText, bodyText);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Button'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
