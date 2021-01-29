import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _text = 'Choose image to upload';
  Isolate _isolate;
  ReceivePort _receivePort;
  SendPort sendPort;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('test isolate storage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SelectableText(
              _text,
            ),
            Text(
              '',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Choose file to upload',
        child: Icon(Icons.file_upload),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _incrementCounter() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );

    /// FIRST CASE - direct upload within main isolate
    /// it works only with
    /// WidgetsFlutterBinding.ensureInitialized();
    /// in the start of the app
    StorageReference ref = FirebaseStorage.instance.ref().child('tests/' + UniqueKey().toString());
    StorageUploadTask uploadTask = ref.putFile(File(result.files.last.path));
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    _text = await storageTaskSnapshot.ref.getDownloadURL();

    ///SECOND CASE - we want to upload with isolate
    _isolate = await Isolate.spawn(upload, File(result.files.last.path));

    setState(() {});
  }

  static void upload(data) async {
    try {
      StorageReference ref = FirebaseStorage.instance.ref().child('tests/' + UniqueKey().toString());
      StorageUploadTask uploadTask = ref.putFile(File(data.files.last.path));
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

    } catch (e) {
      print('+++++error inside isolate - $e');
    }
  }

}
