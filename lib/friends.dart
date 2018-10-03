import 'dart:async';

import 'package:chattao_app/chats.dart';
import 'package:chattao_app/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsPage extends StatelessWidget {
  String currentUserId;
  FriendsPage({@required this.currentUserId}) {}

  Future<SharedPreferences> _getPreference() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  void _toggleOnlineStatus(DocumentSnapshot document) async {
    Firestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(document.reference);
      await transaction
          .update(freshSnap.reference, {'isOnline': !freshSnap['isOnline']});
    });
  }

  void _loadChatScreen(BuildContext context, DocumentSnapshot document) {
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new Chat(
                  peerId: document.documentID,
                  peerAvatar: document['photoUrl'],
                  peerName: document['name'],
                )));
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return new ListTile(
        key: new ValueKey(document.documentID),
        title: new Container(
          decoration: new BoxDecoration(
            border: new Border(
                bottom: BorderSide(
                    width: 1.0,
                    color: const Color(0x88888888),
                    style: BorderStyle.solid)),
            // borderRadius: new BorderRadius.circular(5.0),
          ),
          padding: const EdgeInsets.all(10.0),
          child: new Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                child: CachedNetworkImage(
                  placeholder: Container(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                    width: 40.0,
                    height: 40.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: document['photoUrl'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(
                width: 20.0,
              ),
              new Expanded(
                child: new Text(document['name']),
              ),
              new Text(
                document.documentID.substring(20),
              ),
            ],
          ),
        ),
        onTap: () {
          // _toggleOnlineStatus(document);
          _loadChatScreen(context, document);
        });
  }

  _buildBottomNavBar(BuildContext context) {
    return Material(
      color: themeColor,
      child: SafeArea(
        child: Container(
            padding: EdgeInsets.only(top: 8.0),
            constraints: BoxConstraints(maxHeight: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                NavBarItem(
                  iconData: Icons.chat,
                  title: "Chat",
                  isFocused: true,
                ),
                NavBarItem(iconData: Icons.import_contacts, title: "Contacts"),
                NavBarItem(
                  iconData: Icons.notification_important,
                  title: "Requests",
                  onTap: () {
                    _handleLogout(context);
                  },
                ),
                NavBarItem(
                    iconData: Icons.location_searching, title: "Discover"),
                NavBarItem(iconData: Icons.portrait, title: "Me"),
              ],
            )),
      ),
    );
  }

  _handleLogout(BuildContext context) {
    final GoogleSignIn googleSignIn = new GoogleSignIn();
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    googleSignIn.signOut();
    firebaseAuth.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: new AppBar(
          title: new Text(
            "TaoChat",
            style: TextStyle(color: Colors.white),
          ),
          leading: Container(),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 16.0), child: Icon(Icons.add))
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
        backgroundColor: Color(0xFFBFBFBF),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
                child: TextField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(style: BorderStyle.none)),
                    contentPadding: EdgeInsets.all(0.0),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black,
                    ),
                    fillColor: Colors.white.withAlpha(140),
                    filled: true,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1.0,
                            style: BorderStyle.none),
                        borderRadius: BorderRadius.circular(8.0)),
                    hintText: "Search friend",
                  ),
                ),
              ),
              Expanded(
                child: new StreamBuilder(
                    stream: Firestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        );
                      return new ListView.builder(
                          itemCount: snapshot.data.documents.length,
                          padding: const EdgeInsets.only(top: 10.0),
                          // itemExtent: 25.0,
                          itemBuilder: (context, index) {
                            DocumentSnapshot ds =
                                snapshot.data.documents[index];
                            if (ds.documentID == currentUserId)
                              return Container();
                            return _buildListItem(context, ds);
                          });
                    }),
              ),
            ],
          ),
        ),
      ),
      onWillPop: () {},
    );
  }
}

class NavBarItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final bool isFocused;
  final VoidCallback onTap;

  NavBarItem(
      {@required this.iconData,
      @required this.title,
      this.isFocused = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? onTap,
      child: Container(
        child: Column(
          children: <Widget>[
            Icon(
              iconData,
              color: isFocused ? Colors.orangeAccent : Colors.white,
            ),
            Text(
              title,
              style: TextStyle(
                  color: isFocused ? Colors.orangeAccent : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}