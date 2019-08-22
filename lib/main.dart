import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';
import 'package:zawgyi_converter/zawgyi_detector.dart';
import 'package:floating_search_bar/floating_search_bar.dart';

ZawgyiDetector zawgyiDetector = ZawgyiDetector();
ZawgyiConverter zawgyiConverter = ZawgyiConverter();

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State {
  List<Contact> _contacts, _contactsCopy;

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
                    _contacts = _contactsCopy.where((c)  => c.displayName.contains(value)).toList();
                  });
                } else {
                  setState(() {
                    _contacts = _contactsCopy;
                  });
                }
              },
            ),
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            return (_contacts == null)
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : ListTile(
                    title: Text(
                      _contacts.elementAt(index).displayName,
                      style: TextStyle(fontFamily: 'masterpiece'),
                    ),
                    subtitle: Text(_contacts.elementAt(index).phones.length > 0
                        ? _contacts.elementAt(index).phones.elementAt(0).value
                        : ''),
                  );
          }, childCount: _contacts == null ? 1 : _contacts.length))
        ],
      )),
    );
  }
}
