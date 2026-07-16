import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:validifydart/validify_dart.dart';
import 'route_matching_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  bool? _isLicenceValid;
  bool _isVerifyingLicence = false;

  Future<void> _pickAndVerifyLicence() async {
  final XFile? pickedImage = await _imagePicker.pickImage(
    source: ImageSource.gallery,
  );

  if (pickedImage == null) return;

  setState(() {
    _isLicenceValid = null;
    _isVerifyingLicence = true;
  });

  final TextRecognizer textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  try {
    final InputImage inputImage =
        InputImage.fromFilePath(pickedImage.path);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final String fullText = recognizedText.text;

    debugPrint('OCR Text: $fullText');

    final RegExp licenceRegex = RegExp(
      r'\b[A-Z]{2}\d{2}\s?\d{11}\b',
    );

    final RegExpMatch? match =
        licenceRegex.firstMatch(fullText);

    bool isValid = false;

    if (match != null) {
      final String extractedLicenceNumber =
          match.group(0)!;

      final String cleanedLicenceNumber =
          extractedLicenceNumber.replaceAll(' ', '');

      isValid = ValidifyDart.isValidDrivingLicense(
        cleanedLicenceNumber,
      );

      debugPrint(
        'Is Valid Licence: $isValid',
      );
    } else {
      debugPrint('Licence number not found');
    }

    if (!mounted) return;

    setState(() {
      _isLicenceValid = isValid;
    });
  } catch (e) {
    debugPrint(
      'Licence verification error: $e',
    );

    if (!mounted) return;

    setState(() {
      _isLicenceValid = false;
    });
  } finally {
    textRecognizer.close();

    if (mounted) {
      setState(() {
        _isVerifyingLicence = false;
      });
    }
  }
}

  double _calculateProfileCompletion(
  Map<String, dynamic>? data,
) {
  if (data == null) return 0;

  int completed = 0;

  if ((data['fullName'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  if ((data['employeeId'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  if ((data['mobile'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  if ((data['homeAddress'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  if ((data['officeAddress'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  if ((data['profileImageUrl'] ?? '').toString().isNotEmpty) {
    completed++;
  }

  return completed / 6;
}

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchVehicles() {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  )
      .collection('users')
      .doc(uid)
      .collection('vehicles')
      .get();
}

  Future<void> _showAddVehicleDialog() async {
  final nameController = TextEditingController();
  final colorController = TextEditingController();
  final numberController = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Vehicle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name',
              ),
            ),

            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
              ),
            ),

            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final uid =
                FirebaseAuth.instance.currentUser!.uid;

            await FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            )
                .collection('users')
                .doc(uid)
                .collection('vehicles')
                .add({
              'name': nameController.text.trim(),
              'color': colorController.text.trim(),
              'number': numberController.text.trim(),
            });

            if (mounted) {
              Navigator.pop(context);
              setState(() {});
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

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
            final profileCompletion =
    _calculateProfileCompletion(data);

final profilePercentage =
    (profileCompletion * 100).round();
            final fullName = data?['fullName'] as String? ?? '';
            final employeeId = data?['employeeId'] as String? ?? '';
            final email = data?['email'] as String? ?? '';
            final mobile = data?['mobile'] as String? ?? '';
            final homeAddress = data?['homeAddress'] as String? ?? '';
            final officeAddress = data?['officeAddress'] as String? ?? '';

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
                          value: profileCompletion,
                          strokeWidth: 5,
                          color: Colors.green,
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                      CircleAvatar(
  radius: 50,
  backgroundColor: Colors.grey.shade300,
  child: Text(
    fullName.isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
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
                          child: Text(
                            '$profilePercentage%',
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
  onPressed: () async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          fullName: fullName,
          employeeId: employeeId,
          mobile: mobile,
        ),
      ),
    );

    if (updated == true) {
      setState(() {});
    }
  },
  icon: const Icon(Icons.edit),
  label: const Text('Edit Profile'),
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
                      'Driving Licence Verification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isVerifyingLicence
                                ? null
                                : _pickAndVerifyLicence,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _isVerifyingLicence
                                  ? 'Verifying...'
                                  : 'Upload Driving Licence',
                            ),
                          ),

                          if (_isVerifyingLicence) ...[
                            const SizedBox(height: 16),
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ],

                          if (_isLicenceValid != null &&
                              !_isVerifyingLicence) ...[
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isLicenceValid!
                                      ? Icons.verified
                                      : Icons.cancel,
                                  color: _isLicenceValid!
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isLicenceValid!
                                      ? 'Valid Licence'
                                      : 'Invalid Licence',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isLicenceValid!
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Card(
  child: ListTile(
    leading: const Icon(Icons.route_outlined),
    title: const Text(
      'Route matching',
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: const Text(
      'Routes & Radius settings',
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RouteMatchingPage(),
        ),
      );
    },
  ),
),

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
  context,
  icon: Icons.home,
  title: 'Home',
  address: homeAddress.isNotEmpty
      ? homeAddress
      : 'Add Home Address',
),

const SizedBox(height: 12),

_placeCard(
  context,
  icon: Icons.business,
  title: 'Office',
  address: officeAddress.isNotEmpty
      ? officeAddress
      : 'Add Office Address',
),

                  const SizedBox(height: 30),

                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Favourite Vehicles',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: _showAddVehicleDialog,
    ),
  ],
),

                  const SizedBox(height: 12),

                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
  future: _fetchVehicles(),
  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final vehicles = snapshot.data!.docs;

    if (vehicles.isEmpty) {
      return const Text(
        'No vehicles added',
      );
    }

    return Column(
      children: vehicles.map((vehicle) {

        final data = vehicle.data();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _vehicleCard(
            vehicleId: vehicle.id,
            title: data['name'] ?? '',
            subtitle:
                '${data['color']} • ${data['number']}',
          ),
        );

      }).toList(),
    );
  },
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

  Widget _placeCard(
    BuildContext context,{
    required IconData icon,
    required String title,
    required String address,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(address),
        trailing: IconButton(
  icon: const Icon(Icons.edit),
  onPressed: () async {
  final result = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => LocationSearchPage(
        title: 'Search $title Location',
      ),
    ),
  );

  if (result != null && result.isNotEmpty) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'acepool',
    ).collection('users').doc(uid).update({
      title == 'Home'
          ? 'homeAddress'
          : 'officeAddress': result,
    });

    if (context.mounted) {
      setState(() {});
    }
  }
},
),
      ),
    );
  }

  Widget _vehicleCard({
    required String vehicleId,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
  icon: const Icon(
    Icons.delete_outline,
    color: Colors.red,
  ),
  onPressed: () async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'acepool',
    )
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc(vehicleId)
        .delete();

    setState(() {});
  },
),
      ),
    );
  }
}
