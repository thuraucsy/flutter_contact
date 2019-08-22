import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';
import 'package:zawgyi_converter/zawgyi_detector.dart';

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
  List<Contact> _contacts;

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
          appBar: AppBar(
            title: Text('Welcome to Flutter'),
          ),
          body: (_contacts == null)
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_contacts.elementAt(index).displayName, style: TextStyle(fontFamily: 'masterpiece'),),
                      subtitle: Text(_contacts.elementAt(index).phones.length >
                              0
                          ? _contacts.elementAt(index).phones.elementAt(0).value
                          : ''),
                    );
                  })),
    );
  }
}
