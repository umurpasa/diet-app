import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  Future<void> saveUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('age', ageController.text);
    await prefs.setString('height', heightController.text);
    await prefs.setString('weight', weightController.text);
    await prefs.setString('goal', goalController.text);
    await prefs.setString('allergies', allergiesController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: ageController,
                decoration: InputDecoration(labelText: "Age")),
            TextField(
                controller: heightController,
                decoration: InputDecoration(labelText: "Height (cm)")),
            TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: "Weight (kg)")),
            TextField(
                controller: goalController,
                decoration:
                    InputDecoration(labelText: "Goal (e.g., Lose weight)")),
            TextField(
                controller: allergiesController,
                decoration: InputDecoration(labelText: "Allergies")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                saveUserInfo();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Profile saved!')));
              },
              child: Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
