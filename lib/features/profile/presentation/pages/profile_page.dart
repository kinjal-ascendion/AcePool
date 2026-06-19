import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 12),

              // Profile Image
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
      child: const Icon(Icons.person, size: 50),
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
          "100%",
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

              const Text(
                "Sugandh Srivatava",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "AE25080123",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.edit),
  label: const Text("Edit Profile"),
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

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Saved Places",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              const SizedBox(height: 12),

              _placeCard(
                icon: Icons.home,
                title: "Home",
                address: "Serenity Stays",
              ),

              const SizedBox(height: 12),

              _placeCard(
                icon: Icons.business,
                title: "Office",
                address: "Prestige Sky Tech",
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Favourite Vehicles",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              const SizedBox(height: 12),

              _vehicleCard(
                title: "Tata Harrier",
                subtitle: "Black • 4910",
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
    currentIndex: 3,
    onTap: (index) {
      if (index == 0) {
        Navigator.pop(context);
      }
    },
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