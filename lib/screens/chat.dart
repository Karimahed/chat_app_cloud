import 'package:chat_app/screens/splash.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/widgets/chat_messages.dart';
import 'package:chat_app/widgets/new_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;

  const ChatScreen({super.key, required this.channelId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String channelName = '';

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
    _fetchChannelName();
  }

  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
  }

  Future<void> _fetchChannelName() async {
    try {
      final channelDoc = await FirebaseFirestore.instance.collection('channels').doc(widget.channelId).get();
      if (channelDoc.exists) {
        setState(() {
          channelName = channelDoc['name'];
        });
      }
    } catch (error) {
      print('Error fetching channel name: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              channelName.isNotEmpty ? channelName : 'Loading...',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);

            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white, // Set the back button to white
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                onPressed: () async {
                  try {
                    await AuthService().signOut();

                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => AuthScreen(),
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $error')),
                    );
                  }
                },
                icon: const Icon(
                  Icons.exit_to_app_sharp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: ChatMessages(channelId: widget.channelId)),
              NewMessage(channelId: widget.channelId),
            ],
          ),
        ),
    );
  }
}
