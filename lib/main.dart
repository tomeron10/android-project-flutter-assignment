import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

// #docregion MyApp
class MyApp extends StatelessWidget {
  // #docregion build
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: RandomWords(),
    );
  }
// #enddocregion build
}
// #enddocregion MyApp

// #docregion RWS-var
class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18.0);

  final _authRepository = AuthRepository.instance();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confrimPasswordController = TextEditingController();
  // #enddocregion RWS-var
  bool isdisabled = false;
  bool isPasswordsMatch = true;

  // #docregion _buildSuggestions
  Widget _buildSuggestions() {
    // TODO:
    emailController.text = 'tomeron.firebase@gmail.com';
    passwordController.text = 'jgghjgbmb784654';
    confrimPasswordController.text = 'jgghjgbmb784654';



    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return const Divider(); /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10)); /*4*/
          }
          return _buildRow(_suggestions[index]);
        });
  }
  // #enddocregion _buildSuggestions

  // #docregion _buildRow
  Widget _buildRow(WordPair pair) {
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: ChangeNotifierProvider.value(
          value: _authRepository,
          child: Consumer<AuthRepository>(builder: (context, authInstance, _) {
            final alreadySaved = authInstance.saved.contains(pair);
            return Icon(
              alreadySaved ? Icons.star : Icons.star_border,
              color: alreadySaved ? Colors.deepPurple : null,
              semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
            );
          })),
      onTap: () {
        setState(() {
          if (_authRepository.saved.contains(pair)) {
            _authRepository.removeItem(pair);
          } else {
            _authRepository.addItem(pair);
          }
        });
      },
    );
  }
  // #enddocregion _buildRow

  // #docregion RWS-build
  @override
  Widget build(BuildContext context) {
    _authRepository.loadSaved();
    SnappingSheetController snappingSheetController = SnappingSheetController();

    const bottomSnappingPosition = SnappingPosition.factor(
      positionFactor: 0.0,
      snappingCurve: Curves.easeOutExpo,
      snappingDuration: Duration(seconds: 1),
      grabbingContentOffset: GrabbingContentOffset.top,
    );

    const topSnappingPosition = SnappingPosition.factor(
      positionFactor: 0.25,
      snappingCurve: Curves.bounceOut,
      snappingDuration: Duration(seconds: 1),
      grabbingContentOffset: GrabbingContentOffset.bottom,
    );

    return ChangeNotifierProvider.value(
        value: _authRepository,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Startup Name Generator'),
            actions: [
              IconButton(
                icon: const Icon(Icons.star),
                onPressed: _pushSaved,
                tooltip: 'Saved Suggestions',
              ),
              Consumer<AuthRepository>(
                builder: (context, authInstance, _) => IconButton(
                  icon: Icon(authInstance.isAuthenticated
                      ? Icons.exit_to_app
                      : Icons.login),
                  onPressed: authInstance.isAuthenticated
                      ? () async {
                          await authInstance.signOut();
                          final snackBar = SnackBar(
                              content: Text('Successfully logged out'));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      : _pushLogin,
                  tooltip: 'Saved Suggestions',
                ),
              ),
            ],
          ),
          body: Consumer<AuthRepository>(
            builder: (context, authInstance, _) => !authInstance.isAuthenticated ? _buildSuggestions() :
                SnappingSheet(
              // TODO: Add your content that is placed
              // behind the sheet. (Can be left empty)
              child: _buildSuggestions(),
              grabbingHeight: 50,
              controller: snappingSheetController,

              snappingPositions: [
                bottomSnappingPosition,
                topSnappingPosition,
              ],
              // TODO: Add your grabbing widget here,
              //grabbing: Container(color: Colors.grey),
              grabbing: AnimatedContainer(
                duration: const Duration(seconds: 2),
                child: InkWell(
                  onTap: () {

                    SnappingPosition newPosition;
                    if (snappingSheetController.currentSnappingPosition ==
                        bottomSnappingPosition) {
                      newPosition = topSnappingPosition;
                    } else {
                      newPosition = bottomSnappingPosition;
                    }

                    snappingSheetController.snapToPosition(newPosition);
                  },
                  child: Container(
                    color: Colors.grey,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(child: Text("Welcome back, ${_authRepository.user!.email}"), margin: EdgeInsets.only(left: 15),),
                          //TODO:
                          // child: Text("Welcome back,"),
                          flex: 10,
                        ),
                        Expanded(
                            child: Container(
                          child: Icon(
                            Icons.expand_less,
                          ),
                          alignment: Alignment.centerLeft,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              sheetBelow: SnappingSheetContent(
                draggable: true,
                // TODO: Add your sheet content here
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                    Expanded(
                      child: CircleAvatar(
                          radius: 30,
                          backgroundImage: authInstance.image_url == '' ? null : NetworkImage(authInstance.image_url)),
                    ),
                      Expanded(
                        flex: 3,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: SizedBox(height: 5.0,),),
                            Expanded(child: Text(authInstance.user!.email!, style: TextStyle(fontSize: 20))),
                            Expanded(child: SizedBox(height: 5.0,),),
                            Expanded(child:
                            FlatButton(
                                textColor: Colors.white,
                                color: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0)),
                                minWidth: 65,
                                height: 25,
                                onPressed: () async {
                                  //FirebaseStorage storage =  await FirebaseStorage.instance;
                                  XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

                                  if(file != null)
                                  {
                                    await firebase_storage.FirebaseStorage.instance.ref().child('${authInstance.user!.email!}.png').putFile(File(file.path));
                                    authInstance.loadImage();
                                  }
                                  else
                                  {
                                    SnackBar snackmess = SnackBar(content: Text(
                                        "                      “No image selected"));
                                    ScaffoldMessenger.of(context).showSnackBar(snackmess);
                                  }
                                },
                                child: const Text("Change avatar")))
,                           Expanded(child: SizedBox(height: 5.0,),),

                          ],

                      )),
                  ],),
                ),
              ),
            ),
          ),
        ));
  }
  // #enddocregion RWS-build

  void _pushSaved() async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Saved Suggestions'),
              ),
              body: ListView.separated(
                itemCount: _authRepository.saved.length,
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _authRepository.saved.elementAt(index);
                  return Dismissible(
                    // Each Dismissible must contain a Key. Keys allow Flutter to
                    // uniquely identify widgets.
                    key: Key(item.asPascalCase),
                    background: Container(
                      color: Colors.deepPurple,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 10),
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          Text(
                            'Delete Suggestion',
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),

                    confirmDismiss: (DismissDirection dismissDirection) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete Suggestion'),
                            content: Text(
                                'Are you sure you want to delete $item from your saved suggestions?'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            actions: [
                              FlatButton(
                                  textColor: Colors.white,
                                  color: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  minWidth: 65,
                                  onPressed: () {
                                    setState(() {
                                      _authRepository.removeItem(item);
                                      Navigator.of(context).pop(true);
                                    });
                                  },
                                  child: const Text("Yes")),
                              FlatButton(
                                textColor: Colors.white,
                                color: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
                                minWidth: 65,
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("No"),
                              ),
                            ],
                          );
                        },
                      );
                    },

                    child: ListTile(
                      title: Text(item.asPascalCase),
                    ),
                  );
                },
              ));
        },
      ),
    );
  }

  void _pushLogin() {

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ChangeNotifierProvider.value(
              value: _authRepository,
              child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Login'),
                    centerTitle: true,
                  ),
                  body: Container(
                    child: ListView(children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 25, left: 25, right: 25),
                          child: Text(
                              'Welcome to Startup Names Generator, please log in below')),
                      Container(
                          margin: EdgeInsets.only(top: 25, left: 25, right: 25),
                          child: TextField(
                            decoration: InputDecoration(hintText: 'Email'),
                            controller: emailController,
                          )),
                      Container(
                          margin: EdgeInsets.only(top: 25, left: 25, right: 25),
                          child: TextField(
                            decoration: InputDecoration(hintText: 'Password'),
                            controller: passwordController,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                          )),
                      Container(
                          margin: EdgeInsets.only(top: 15, left: 25, right: 25),
                          child: Consumer<AuthRepository>(
                              builder: (context, authInstance, _) =>
                                  ElevatedButton(
                                    onPressed: authInstance.status ==
                                            Status.Authenticating
                                        ? null
                                        : () async {
                                            bool signInResult =
                                                await authInstance.signIn(
                                                    emailController.text,
                                                    passwordController.text);
                                            if (signInResult) {
                                              Navigator.of(context).pop();
                                            } else {
                                              final snackBar = SnackBar(
                                                  content: Text(
                                                      'There was an error logging into the app'));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(snackBar);
                                            }
                                          },
                                    child: Text('Log in'),
                                    style: ElevatedButton.styleFrom(
                                        primary: Colors.deepPurple,
                                        shape: StadiumBorder()),
                                  ))),
                      Container(
                          margin: EdgeInsets.only(top: 5, left: 25, right: 25),
                          child: Consumer<AuthRepository>(
                              builder:
                                  (context, authInstance, _) => ElevatedButton(
                                        onPressed:
                                            authInstance.status ==
                                                    Status.Authenticating
                                                ? null
                                                : () async {
                                                    bool returnValue =
                                                        await showModalBottomSheet(
                                                            backgroundColor:
                                                                Colors.white,
                                                            context: context,
                                                            isScrollControlled:
                                                                true,
                                                            builder:
                                                                (context) =>
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              15),
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: <
                                                                            Widget>[
                                                                          Text(
                                                                              'Please confrim your password below',
                                                                              style: TextStyle(fontSize: 16)),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 25),
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                TextField(
                                                                                  controller: confrimPasswordController,
                                                                                  decoration: InputDecoration(
                                                                                      labelText: 'Password',fillColor: Colors.red,
                                                                                      errorText: isPasswordsMatch ? null : 'Passwords must match'),
                                                                                  obscureText: true,
                                                                                  enableSuggestions: false,
                                                                                  autocorrect: false,
                                                                                  //autofocus: true,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                                              child: ElevatedButton(
                                                                                child: Text('Confrim'),
                                                                                onPressed: isdisabled
                                                                              ? null : () async {
                                                                                  if (confrimPasswordController.text != passwordController.text) {
                                                                                    confrimPasswordController.text = '';
                                                                                    isPasswordsMatch = false;

                                                                                    // final snackBar = SnackBar(
                                                                                    //     content: Text('The passwords do not match. Please try again.'));
                                                                                    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                                                    //Navigator.of(context).pop(false);
                                                                                  } else {

                                                                                      isdisabled = true;
                                                                                    final newUser = await authInstance.signUp(emailController.text, passwordController.text);
                                                                                      isdisabled = false;


                                                                                    if(newUser != null){
                                                                                      Navigator.of(context).pop(true);
                                                                                    } else {
                                                                                      final snackBar = SnackBar(
                                                                                          content: Text('Sign up failed. Please try again.'));
                                                                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                                                      Navigator.of(context).pop(false);
                                                                                    }


                                                                                  }
                                                                                },
                                                                              )),
                                                                        ],
                                                                      ),
                                                                    ));

                                                    if (returnValue) {
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  },
                                        child:
                                            Text('New user? Click to sign up'),
                                        style: ElevatedButton.styleFrom(
                                            primary: Colors.blue,
                                            shape: StadiumBorder()),
                                      ))),
                    ]),
                  )));
        },
      ),
    );
  }
// #docregion RWS-var
}

class RandomWords extends StatefulWidget {
  @override
  State<RandomWords> createState() => _RandomWordsState();
}
