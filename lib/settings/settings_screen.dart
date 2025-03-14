import 'package:flutter/material.dart';

import '../grinder/coffee_grinder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Профиль пользователя',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Данные профиля будут добавлены в будущем.'),
            const SizedBox(height: 32),
            ListTile(
              title: const Text('Мои кофемолки'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoffeeGrinderScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
