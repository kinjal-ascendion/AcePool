import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'acepool',
    ).collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final fullName = data?['fullName'] as String? ?? '';
            final employeeId = data?['employeeId'] as String? ?? '';
            final email = data?['email'] as String? ?? '';
            final mobile = data?['mobile'] as String? ?? '';

            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Profile avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 5,
                          color: Colors.green,
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        child: isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Text(
                                fullName.isNotEmpty
                                    ? fullName
                                        .trim()
                                        .split(' ')
                                        .take(2)
                                        .map((w) => w[0].toUpperCase())
                                        .join()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '100%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  isLoading
                      ? const SizedBox(
                          height: 32,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Text(
                          fullName.isNotEmpty ? fullName : '—',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                  const SizedBox(height: 4),

                  Text(
                    isLoading ? '' : (employeeId.isNotEmpty ? employeeId : '—'),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Contact info
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contact Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (!isLoading) ...[
                    _infoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: email.isNotEmpty ? email : '—',
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      icon: Icons.phone_outlined,
                      title: 'Mobile',
                      value: mobile.isNotEmpty ? '+91 $mobile' : '—',
                    ),
                  ],

                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saved Places',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _placeCard(
                    icon: Icons.home,
                    title: 'Home',
                    address: 'Serenity Stays',
                  ),

                  const SizedBox(height: 12),

                  _placeCard(
                    icon: Icons.business,
                    title: 'Office',
                    address: 'Prestige Sky Tech',
                  ),

                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Favourite Vehicles',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _vehicleCard(
                    title: 'Tata Harrier',
                    subtitle: 'Black • 4910',
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  static Widget _placeCard({
    required IconData icon,
    required String title,
    required String address,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(address),
        trailing: const Icon(Icons.edit),
      ),
    );
  }

  static Widget _vehicleCard({
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),
    );
  }
}
