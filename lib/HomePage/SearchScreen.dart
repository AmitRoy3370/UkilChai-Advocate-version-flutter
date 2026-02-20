import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    
    return SearchScreenState();
    
  }

}

class SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {

    return const Center(
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search advocates and legal article at here...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(10),
          hintStyle: TextStyle(color: Colors.grey),

        ),
        style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.normal
        ),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLines: 3,
        minLines: 1,

      ),
    );

  }

}