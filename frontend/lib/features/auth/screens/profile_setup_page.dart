import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solution_challenge/home_page.dart';


class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _addictionTypes = ['Alcohol', 'Drugs', 'Other'];
  final List<String> _triggers = ['Stress', 'Social Events', 'Boredom', 'Emotional Distress'];
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedAddictionType = 'Alcohol';
  final List<String> _selectedTriggers = [];
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _supportSystemController = TextEditingController();

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': _nameController.text,
                'age': int.parse(_ageController.text),
                'gender': _selectedGender,
                'addictionType': _selectedAddictionType,
                'triggers': _selectedTriggers,
                'goals': _goalsController.text,
                'supportSystem': _supportSystemController.text,
                'createdAt': Timestamp.now(),
              });

              final userData = await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .get();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );

          print(userData);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty || int.tryParse(value) == null 
                    ? 'Please enter valid age' 
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedAddictionType,
                items: _addictionTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAddictionType = value!),
                decoration: const InputDecoration(labelText: 'Addiction Type'),
              ),
              const SizedBox(height: 16),
              const Text('Common Triggers:'),
              ..._triggers.map((trigger) => CheckboxListTile(
                    title: Text(trigger),
                    value: _selectedTriggers.contains(trigger),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value!) {
                          _selectedTriggers.add(trigger);
                        } else {
                          _selectedTriggers.remove(trigger);
                        }
                      });
                    },
                  )),
              TextFormField(
                controller: _goalsController,
                decoration: const InputDecoration(labelText: 'Recovery Goals'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter your goals' : null,
              ),
              TextFormField(
                controller: _supportSystemController,
                decoration: const InputDecoration(labelText: 'Support System (family/friends)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Complete Profile Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}