import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(user),
          const SizedBox(height: 28),

          _sectionTitle('DEVICE'),
          _pairingCard(context, uid),

          _settingsTile(
            icon: Icons.wifi,
            title: 'WiFi Configuration',
            subtitle: 'Connect feeder to internet',
            trailing: const Chip(
              label: Text('Guide'),
              backgroundColor: Color(0xFFE6F6EC),
              labelStyle: TextStyle(color: Colors.green),
            ),
            onTap: () => _openWifiInfo(context),
          ),

          const SizedBox(height: 32),
          _logoutButton(context),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              'AQUAFEEDY v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /* =====================================================
     PROFILE
  ===================================================== */

  Widget _profileCard(User user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF2EC4F1),
            child: Text(
              user.email![0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UID: ${user.uid.substring(0, 8)}•••',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =====================================================
     PAIRING CARD
  ===================================================== */

  Widget _pairingCard(BuildContext context, String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String? feederId = data['feederId'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Feeder Pairing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(feederId != null),
                ],
              ),
              const SizedBox(height: 12),

              if (feederId == null) ...[
                const Text(
                  'No feeder paired to this account.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _showPairDialog(context, uid),
                  icon: const Icon(Icons.add),
                  label: const Text('Pair New Feeder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC4F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Feeder ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feederId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'feederId': FieldValue.delete()});
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text('Unpair Feeder'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        connected ? 'CONNECTED' : 'NOT PAIRED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: connected ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  /* =====================================================
     PAIR DIALOG
  ===================================================== */

  void _showPairDialog(BuildContext context, String uid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Pair Feeder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Feeder ID',
            hintText: 'e.g. feeder-001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final feederId = controller.text.trim().toLowerCase();
              if (feederId.isEmpty) return;

              try {
                final status = await FirebaseFirestore.instance
                    .collection('feeders')
                    .doc(feederId)
                    .collection('status')
                    .doc('current')
                    .get();

                if (!status.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feeder not found')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({'feederId': feederId}, SetOptions(merge: true));

                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pairing failed: $e')),
                );
              }
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  /* =====================================================
     UI HELPERS
  ===================================================== */

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2EC4F1)),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Log Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  void _openWifiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('WiFi Configuration'),
        content: const Text(
          '1. Turn on feeder\n'
          '2. Connect to feeder hotspot\n'
          '3. Captive portal will open\n'
          '4. Select WiFi & save',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
