import 'package:flutter/material.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: 40,
      width: 190,
      child: Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(left: 12, right: 5),
        elevation: 2,
        child: const ListTile(
          title: Text(
            "Al Ghaaaashiyah",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("24/192 Ayahs"),
        ),
      ),
    );
  }
}
