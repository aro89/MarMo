import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madmet/pages/create_account.dart';
import 'package:madmet/pages/login.dart';
import 'package:madmet/theme/color.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool showDeleteAccount = false;
  bool showPrivacyPolicy = false;
  bool showLogout = false;

  final user = FirebaseAuth.instance.currentUser;

  void _toggleSection(String section) {
    setState(() {
      if (section == 'delete') {
        showDeleteAccount = !showDeleteAccount;
        showPrivacyPolicy = false;
        showLogout = false;
      } else if (section == 'privacy') {
        showPrivacyPolicy = !showPrivacyPolicy;
        showDeleteAccount = false;
        showLogout = false;
      } else if (section == 'logout') {
        showLogout = !showLogout;
        showDeleteAccount = false;
        showPrivacyPolicy = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = user?.photoURL;
    final email = user?.email;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Profile", style: TextStyle(fontSize: 24)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 90,
              backgroundImage: profileImage != null
                  ? NetworkImage(profileImage)
                  : const AssetImage('assets/images/default-avatar-profile-icon.png') as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(email ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),

            _buildOption(
              icon: Icons.delete_forever,
              label: "Delete Account",
              isExpanded: showDeleteAccount,
              onTap: () => _toggleSection('delete'),
            ),
            if (showDeleteAccount) _buildDeleteConfirmation(),

            _buildOption(
              icon: Icons.privacy_tip,
              label: "Privacy Policy",
              isExpanded: showPrivacyPolicy,
              onTap: () => _toggleSection('privacy'),
            ),
            if (showPrivacyPolicy) _buildPrivacyPolicyPrompt(),

            _buildOption(
              icon: Icons.logout,
              label: "Logout",
              isExpanded: showLogout,
              onTap: () => _toggleSection('logout'),
            ),
            if (showLogout) _buildLogoutConfirmation(),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black, size: 25),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.arrow_forward_ios,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const Text(
            "Are you sure you want to delete your account? This cannot be undone.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final firestoreService = FirestoreService();
                final userId = user?.uid ?? '';

                final transactions = await firestoreService.getTransactions(userId);
                await firestoreService.batchDeleteDocuments(userId, 'transactions',
                    transactions.map((t) => t.id).toList());

                final wallets = await firestoreService.getWallets(userId);
                await firestoreService.batchDeleteDocuments(userId, 'wallets',
                    wallets.map((w) => w.id).toList());

                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                await user?.delete();
                await FirebaseAuth.instance.signOut();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateAccountPage()),
                        (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete Account Forever", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const Text(
            "Click below to view our Privacy Policy.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () async {
              final url = Uri.parse('https://www.yourwebsite.com/privacy-policy');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Could not launch URL"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("View Privacy Policy", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutConfirmation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const Text(
            "Are you sure you want to logout?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}
