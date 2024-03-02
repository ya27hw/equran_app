import 'package:flutter/material.dart';

class MySearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final TextEditingController _controller = TextEditingController();
  MySearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 27),
      child: SearchBar(
          padding: const MaterialStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16)),
          leading: const Icon(Icons.search),
          hintText: "Search...",
          //controller: _controller,
          trailing: _controller.text.isNotEmpty
              ? [
                  IconButton(
                    onPressed: () {
                      _clearText();
                    },
                    icon: const Icon(Icons.clear),
                  )
                ]
              : null,
          onChanged: onChanged),
    );
  }

  void _clearText() {
    _controller.clear();
  }
}
