import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;


enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;

  var _saved = <WordPair>{};
  final String _savedCollectionName = 'saved';
  final String _usersCollectionName = 'users';
  String _image_url = '';

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  String get image_url => _image_url;

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Set<WordPair> get saved => _saved;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      var return_value =
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      notifyListeners();
      return return_value;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveAllItems(_savedCollectionName);
      _saved = await _getAllItems(_savedCollectionName);
      try {
        _image_url = await firebase_storage.FirebaseStorage.instance.ref().child('test1.png').getDownloadURL();
        print(_image_url);
      }
      catch (e) {
        print('test');
        print(e);
        return false;
      }
      // print('test');
      // print(_image_url);
      print(isAuthenticated);
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future loadSaved() async {
    if(isAuthenticated) {
      _saved = await _getAllItems(_savedCollectionName);
      _image_url = await firebase_storage.FirebaseStorage.instance.ref().child('${user!.email!}.png').getDownloadURL();
      notifyListeners();
    }
  }

  Future loadImage() async {
    if(isAuthenticated) {
      _image_url = await firebase_storage.FirebaseStorage.instance.ref().child('${user!.email!}.png').getDownloadURL();
      notifyListeners();
    }
  }

  Future signOut() async {
    _saved.clear();
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future _saveAllItems(String collectionName) async {
    _saved.forEach((element) async {
      await saveItem(element, collectionName);
    });
  }

  Future<Set<WordPair>> _getAllItems(String collectionName) async {
    Set<WordPair> saved = <WordPair>{};

    CollectionReference savedCollection = FirebaseFirestore.instance
        .collection(_usersCollectionName)
        .doc(user!.email.toString())
        .collection(collectionName);

    await savedCollection.get().then((querySnapshot) {
      for (var result in querySnapshot.docs) {
        String first = result.get('first').toString();
        String second = result.get('second').toString();
        saved.add(WordPair(first, second));
      }
    });

    return Future<Set<WordPair>>.value(saved);
  }

  Future addItem(WordPair pair) async {
    _saved.add(pair);
    saveItem(pair, _savedCollectionName);
  }

  Future saveItem(WordPair pair, String collectionName) async {
    if (isAuthenticated) {
      FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .doc(user!.email.toString())
          .collection(collectionName)
          .doc(pair.asPascalCase)
          .set({'first': pair.first, 'second': pair.second});
    }
  }

  Future removeItem(WordPair pair) async {
    _saved.remove(pair);

    if (isAuthenticated) {
      CollectionReference saved = FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .doc(user!.email.toString())
          .collection(_savedCollectionName);
      saved.doc(pair.asPascalCase).delete();
    }
  }
}
