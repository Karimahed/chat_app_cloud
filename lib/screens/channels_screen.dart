import 'package:chat_app/services/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'auth.dart';
import 'chat.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _analytics = AnalyticsService();

  List<Map<String, dynamic>> _allChannels = [];
  List<String> _subscribedChannels = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllChannels();
  }

  Future<void> _fetchAllChannels() async {
    setState(() {
      _loading = true;
    });

    try {
      final channelsSnapshot = await _firestore
          .collection('channels')
          .orderBy('createdAt', descending: false)
          .get();
      final channels = channelsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'description': doc['description'],
              })
          .toList();

      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final userSubscribedChannels =
          userDoc.data()?['subscribedChannels'] as List<dynamic>? ?? [];

      setState(() {
        _allChannels = channels;
        _subscribedChannels = userSubscribedChannels.cast<String>();
        _loading = false;
      });
    } catch (error) {
      print('Error fetching channels: $error');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleChannelSubscription(String channelId) async {
    final isSubscribed = _subscribedChannels.contains(channelId);
    if (isSubscribed) {
      setState(() {
        _subscribedChannels.remove(channelId);
      });
      FirebaseMessaging.instance.unsubscribeFromTopic(channelId);
      await _analytics.unsubscribe(channelId, _auth.currentUser!.uid);

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'subscribedChannels': FieldValue.arrayRemove([channelId]),
      });
    } else {
      setState(() {
        _subscribedChannels.add(channelId);
      });
      FirebaseMessaging.instance.subscribeToTopic(channelId);
      await _analytics.subscribeToChannel(channelId, _auth.currentUser!.uid);
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'subscribedChannels': FieldValue.arrayUnion([channelId]),
      });
    }
  }

  void _navigateToChatRoom(String channelId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChatScreen(channelId: channelId),
      ),
    );
  }

  void _showAddChannelDialog() {
    final _channelNameController = TextEditingController();
    final _channelDescriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _channelNameController,
              decoration: const InputDecoration(labelText: 'Channel Name'),
            ),
            TextField(
              controller: _channelDescriptionController,
              decoration:
                  const InputDecoration(labelText: 'Channel Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final channelName = _channelNameController.text;
              final channelDescription = _channelDescriptionController.text;

              _addNewChannel(channelName, channelDescription);

              Navigator.of(ctx).pop();
            },
            child: const Text('Create Channel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewChannel(
      String channelName, String channelDescription) async {
    if (channelName.isEmpty || channelDescription.isEmpty) {
      return;
    }

    final newChannel = await _firestore.collection('channels').add({
      'name': channelName,
      'description': channelDescription,
      'createdAt': Timestamp.now(),
    });

    await _toggleChannelSubscription(newChannel.id);
    _fetchAllChannels();
  }

  Future<void> _deleteChannel(String channelId) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userSubscribedChannels =
            List<String>.from(userDoc['subscribedChannels'] ?? []);

        if (userSubscribedChannels.contains(channelId)) {
          await _firestore.collection('users').doc(userDoc.id).update({
            'subscribedChannels': FieldValue.arrayRemove([channelId]),
          });
        }
      }

      await _firestore.collection('channels').doc(channelId).delete();
      _fetchAllChannels();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Channel "$channelId" deleted successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting channel: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text(
          'Channels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        automaticallyImplyLeading: false,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: _firestore.collection('channels').snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> channelSnapshot) {
                if (channelSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final channels = channelSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (ctx, index) {
                    final channel = channels[index];
                    final channelId = channel.id;
                    final channelName = channel['name'];
                    final channelDescription = channel['description'];

                    final isSubscribed =
                        _subscribedChannels.contains(channelId);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          title: Text(
                            channelName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            channelDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () =>
                                      _toggleChannelSubscription(channelId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubscribed
                                        ? Colors.red
                                        : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isSubscribed ? 'Leave' : 'Join',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                          onTap: isSubscribed
                              ? () => _navigateToChatRoom(channelId)
                              : null,
                          onLongPress: () async {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Channel'),
                                content: const Text(
                                    'Are you sure you want to delete this channel?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _deleteChannel(channelId);
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChannelDialog,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
