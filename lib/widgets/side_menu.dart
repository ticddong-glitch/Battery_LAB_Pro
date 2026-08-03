import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 25),

            const Icon(
              Icons.battery_charging_full,
              color: Colors.green,
              size: 60,
            ),

            const SizedBox(height: 10),

            const Text(
              "Battery LAB Pro",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 40),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Export Excel"),
              onTap: () {},
            ),

            const Spacer(),

            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Battery LAB Pro v1.0",
                style: TextStyle(color: Colors.grey),
              ),
            )

          ],
        ),
      ),
    );
  }
}