import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';
import 'package:zawgyi_converter/zawgyi_detector.dart';
import 'package:floating_search_bar/floating_search_bar.dart';
import 'package:flare_flutter/flare_actor.dart';

ZawgyiDetector zawgyiDetector = ZawgyiDetector();
ZawgyiConverter zawgyiConverter = ZawgyiConverter();

void main() => runApp(MyStatelessApp());

class MyStatelessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyStatefulApp(),
    );
  }
}

class MyStatefulApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State {
  List<Contact> _contacts, _contactsCopy;
  Set<Contact> _saved = Set<Contact>();

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ??
          PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  refreshContact() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      Iterable<Contact> contacts = await ContactsService.getContacts();

      List<Contact> zawgyiContacts = [];
      contacts.map((c) {
        if (zawgyiDetector.predict(c.displayName) > 0.05) {
          c.displayName = zawgyiConverter.zawgyiToUnicode(c.displayName);
          zawgyiContacts.add(c);
        }
      }).toList();

      setState(() {
        _contacts = zawgyiContacts;
      });
      _contactsCopy = _contacts;
    }
  }

  @override
  void initState() {
    super.initState();
    refreshContact();
  }

  Widget _buildRow(Contact contact) {
    bool alreadySaved = _saved.contains(contact);

    return (contact == null)
        ? Center(
            child: CircularProgressIndicator(),
          )
        : ListTile(
            title: Text(
              contact.displayName,
              style: TextStyle(fontFamily: 'masterpiece'),
            ),
            subtitle: Text(contact.phones.length > 0
                ? contact.phones.elementAt(0).value
                : ''),
            trailing: SizedBox(
              width: 50,
              height: 50,
              child: GestureDetector(
                child: FlareActor(
                  'assets/favorite.flr',
                  animation: alreadySaved ? 'Favorite' : 'Unfavorite',
                ),
//                IconButton(
//                  icon: Icon(alreadySaved
//                      ? Icons.favorite
//                      : Icons.favorite_border,
//                  color: alreadySaved ? Colors.red: null,),
//                ),
                onTap: () {
                  print('iconbutton');
                  setState(() {
                    if (alreadySaved) {
                      _saved.remove(contact);
                    } else {
                      _saved.add(contact);
                    }
                  });
                },
              ),
            ),
          );
  }

  void _pushSaved() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Saved List'),
        ),
        body: ListView.builder(
            itemCount: _saved.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_saved.elementAt(index).displayName),
                subtitle: Text(_saved.elementAt(index).phones.length > 0
                    ? _saved.elementAt(index).phones.elementAt(0).value
                    : ''),
              );
            }),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
          body: CustomScrollView(
        slivers: <Widget>[
          SliverFloatingBar(
            title: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Search...'),
              onChanged: (value) {
                if (zawgyiDetector.predict(value) > 0.05) {
                  value = zawgyiConverter.zawgyiToUnicode(value);
                }
                print('changing $value');

                if (value.isNotEmpty) {
                  setState(() {
                    _contacts = _contactsCopy
                        .where((c) => c.displayName.contains(value))
                        .toList();
                  });
                } else {
                  setState(() {
                    _contacts = _contactsCopy;
                  });
                }
              },
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.favorite,
                color: Colors.red.shade400,
              ),
              onPressed: _pushSaved,
            ),
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            return _buildRow(_contacts?.elementAt(index));
          }, childCount: _contacts == null ? 1 : _contacts.length))
        ],
      )),
    );
  }
}
