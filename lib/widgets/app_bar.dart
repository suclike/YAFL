import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:yafl/models/user_model.dart';

Widget scopedAppBar(UserModel model) {
  return AppBar(
    title: Image.asset('images/logo_name_white_300.png', fit: BoxFit.contain, height: 40),
    backgroundColor: Colors.grey[900],
    primary: true,
    elevation: 0.0,
    centerTitle: true,
    actions: model.isSignedIn
        ? <Widget>[
            IconButton(
              icon: Icon(MdiIcons.settings),
              iconSize: 30,
              onPressed: () => model.signout(),
            ),
            GestureDetector(
              onTap: () => model.signout(),
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: model.user.photoUrl != null
                      ? ClipOval(child: Image.network(model.user.photoUrl, fit: BoxFit.cover))
                      : Icon(
                          MdiIcons.accountCircle,
                          size: 30,
                        )),
            ),
            IconButton(
              icon: Icon(MdiIcons.logoutVariant),
              iconSize: 30,
              onPressed: () => model.signout(),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            )
          ]
        : [],
  );
}
