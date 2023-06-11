import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class MenuPage extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const MenuPage({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  TextEditingController _textEditingController = TextEditingController();
  Map<int, String> suggestionMap = {};
  List<String> filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    retrievePatientsFromFirebase();
    _textEditingController.addListener(filterSuggestions);
  }

  Future<void> retrievePatientsFromFirebase() async {
    try {
      final ListResult listResult = await FirebaseStorage.instance.ref().listAll();
      final List<Reference> folderRefs = listResult.prefixes;

      for (final Reference folderRef in folderRefs) {
        print('Foldername: ${folderRef.name}');
        suggestionMap[int.parse(folderRef.name)] = "";
      }
    } catch (e) {
      print('Firebase Storage retrieve patients error: $e');
    }
  }

  void filterSuggestions() {
    String filterText = _textEditingController.text.toLowerCase();
    setState(() {
      filteredSuggestions = suggestionMap.entries
          .where((entry) =>
      entry.key.toString().startsWith(filterText) ||
          entry.value.toLowerCase().startsWith(filterText))
          .map((entry) => '${entry.key}')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Lesion Meter',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type the id of the patient.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _textEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sayısal değer girin',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              style: TextStyle(
                color: Colors.indigo,
              ),
              onChanged: (value) {
                filterSuggestions();
              },
              onSubmitted: (value) {
                widget.onSubmit(_textEditingController.text);
              },
            ),
            SizedBox(height: 10),
            Text('Recents:'),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: filteredSuggestions.length > 7 ? 7 : filteredSuggestions.length,
                  physics: BouncingScrollPhysics(), // veya ClampingScrollPhysics()
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(filteredSuggestions[index]),
                        onTap: () {
                          _textEditingController.text = filteredSuggestions[index].split(' ')[0];
                          widget.onSubmit(_textEditingController.text);
                          },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
