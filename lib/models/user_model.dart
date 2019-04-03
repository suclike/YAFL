import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scoped_model/scoped_model.dart';

class UserModel extends Model {
  FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  FacebookLogin _facebookLogin = FacebookLogin();

  FirebaseUser _user;

  FirebaseUser get user => _user;

  String _errMessage;

  String get errMessage => _errMessage;

  set errMessageNull(bool nullify) {
    if (nullify) {
      _errMessage = null;
    }
  }

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    initUser();
  }

  initUser() async {
    startLoading();
    _user = await _auth.currentUser();
    if (_user != null) {
      _isSignedIn = true;
    }
    stopLoading();
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void caughtExc(exc) {
    print(exc);
    _errMessage = exc.toString();
    if (exc is PlatformException) {
      _errMessage = exc.message;
    }
    notifyListeners();
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
    if (_user != null) {
      List<UserInfo> providers = _user.providerData;
      providers.forEach((u) => forceSignout(u));
    }
    _user = null;
    _isSignedIn = false;
    notifyListeners();
  }

  forceSignout(UserInfo u) async {
    switch (u.providerId) {
      case 'google.com':
        await _googleSignIn.signOut();
        break;
      case 'facebook.com':
        await _facebookLogin.logOut();
        break;
    }
  }

  assertUser() async {
    if (_user != null) {
      try {
        assert(_user.email != null);
        assert(!_user.isAnonymous);
        assert(await _user.getIdToken() != null);
        FirebaseUser currentUser = await _auth.currentUser();
        assert(_user.uid == currentUser.uid);
        print('Logged in: ${_user.displayName}');
        _isSignedIn = true;
        _user = currentUser;
      } catch (exc) {
        caughtExc(exc);
        signout();
        return null;
      }
    } else {
      signout();
    }
    stopLoading();
  }

  sendTokenToServer(credential) async {
    try {
      _user = await _auth.signInWithCredential(credential);
    } catch (exc) {
      caughtExc(exc);
      signout();
      return null;
    }
    assertUser();
  }

  signInWithGoogle() async {
    startLoading();
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      sendTokenToServer(credential);
    } catch (exc) {
      caughtExc(exc);
      signout();
      return null;
    }
  }

  signinWithFacebook() async {
    startLoading();
    try {
      final result = await _facebookLogin.logInWithReadPermissions(['email']);
      switch (result.status) {
        case FacebookLoginStatus.loggedIn:
          final credential = FacebookAuthProvider.getCredential(accessToken: result.accessToken.token);
          sendTokenToServer(credential);
          break;
        case FacebookLoginStatus.cancelledByUser:
          signout();
          break;
        case FacebookLoginStatus.error:
          caughtExc(result.errorMessage);
          signout();
          break;
      }
    } catch (exc) {
      caughtExc(exc);
      signout();
      return null;
    }
  }

  signinWithEmailAndPassword(String email, String password) async {
    startLoading();
    _user = await _auth.signInWithEmailAndPassword(email: email, password: password).catchError((err) {
      caughtExc(err);
      signout();
    });
    assertUser();
  }

  createUserWithEmailAndPassword(String name, String email, String password) async {
    startLoading();
    try {
      _user = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      UserUpdateInfo uui = UserUpdateInfo();
      uui.displayName = name;
      _user.updateProfile(uui);
    } catch (exc) {
      caughtExc(exc);
      signout();
      return null;
    }
    assertUser();
  }

  sendPasswordResetEmail(String email) async {
    _auth.sendPasswordResetEmail(email: email).catchError((err) {
      caughtExc(err);
    });
  }
}
