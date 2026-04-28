import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'schedule_page.dart';
import 'ai_agent_page.dart';
import 'settings_page.dart';

/* ============================================================
   HOME PAGE
============================================================ */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  final List<Widget> _pages = const [
    HomeDashboard(),
    SchedulePage(),
    AiAgentPage(),
    SettingsPage(),
  ];

  @override
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      body: SafeArea(child: _pages[_navIndex]),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔧 FIX: sembunyikan FAB hanya di AI page (index 2)
      floatingActionButton: _navIndex == 2
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF2EC4F1),
              onPressed: () => _showDispenseDialog(context),
              child: const Icon(Icons.water_drop, size: 28),
            ),
    );
  }
}

/* ============================================================
   HOME DASHBOARD
============================================================ */

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  Stream<String?> feederIdStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['feederId']);
  }

  String wifiQuality(int? rssi) {
    if (rssi == null) return '--';
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: feederIdStream(),
      builder: (context, feederSnap) {
        if (feederSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feederSnap.data == null) {
          return const Center(
            child: Text(
              'No feeder paired\nPlease pair your device in Settings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final feederId = feederSnap.data!;

        final statusRef = FirebaseFirestore.instance
            .collection('feeders')
            .doc(feederId)
            .collection('status')
            .doc('current');

        final scheduleRef = FirebaseFirestore.instance
            .collection('feeders')
            .doc(feederId)
            .collection('schedules')
            .where('enabled', isEqualTo: true);

        return StreamBuilder<DocumentSnapshot>(
          stream: statusRef.snapshots(),
          builder: (context, statusSnap) {
            final data =
                statusSnap.data?.data() as Map<String, dynamic>? ?? {};

            final Timestamp? lastPing = data['lastPing'];
            final bool online = lastPing != null &&
                DateTime.now()
                        .difference(lastPing.toDate())
                        .inSeconds <
                    30;

            final int food = (data['foodLevel'] ?? 0).clamp(0, 100);
            final int? rssi = data['rssi'];

            final Timestamp? lastFedTs = data['lastFed'];
            final String lastFed = lastFedTs != null
                ? TimeOfDay.fromDateTime(lastFedTs.toDate()).format(context)
                : '--';

            return StreamBuilder<QuerySnapshot>(
              stream: scheduleRef.snapshots(),
              builder: (context, schedSnap) {
                String nextFeed = 'No Schedule';

                if (schedSnap.hasData && schedSnap.data!.docs.isNotEmpty) {
                  final now = DateTime.now();
                  DateTime? nearest;

                  for (var doc in schedSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final int hour = d['hour'];
                    final int minute = d['minute'];
                    final List<int> days = List<int>.from(d['days']);

                    for (int day in days) {
                      // Firestore: 0=Sun ... 6=Sat
                      // Dart: 1=Mon ... 7=Sun
                      int dartDay = day == 0 ? 7 : day;

                      int diff = dartDay - now.weekday;
                      if (diff < 0) diff += 7;

                      DateTime candidate = DateTime(
                        now.year,
                        now.month,
                        now.day + diff,
                        hour,
                        minute,
                      );

                      // kalau hari sama tapi jam sudah lewat → minggu depan
                      if (candidate.isBefore(now)) {
                        candidate = candidate.add(const Duration(days: 7));
                      }

                      if (nearest == null || candidate.isBefore(nearest)) {
                        nearest = candidate;
                      }
                    }
                  }

                  if (nearest != null) {
                    nextFeed = TimeOfDay.fromDateTime(nearest).format(context);
                  }
                }

                return _DashboardUI(
                  online: online,
                  food: food,
                  wifiSignal: wifiQuality(rssi),
                  lastFed: lastFed,
                  nextFeed: nextFeed,
                );
              },
            );
          },
        );
      },
    );
  }
}

/* ============================================================
   DASHBOARD UI
============================================================ */

class _DashboardUI extends StatelessWidget {
  final bool online;
  final int food;
  final String wifiSignal;
  final String lastFed;
  final String nextFeed;

  const _DashboardUI({
    required this.online,
    required this.food,
    required this.wifiSignal,
    required this.lastFed,
    required this.nextFeed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _statusCard(context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  title: 'Last Feed',
                  value: lastFed,
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(
                  title: 'WiFi Signal',
                  value: wifiSignal,
                  icon: Icons.wifi,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Feeder',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Smart Aquarium',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        _ConnectionBadge(online: online),
      ],
    );
  }

  Widget _statusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF5DA9FF), Color(0xFF2EC4F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusItem(label: 'Food Level', value: '$food%'),
              ),
              Expanded(
                child: _StatusItem(label: 'Next Feed', value: nextFeed),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: food / 100,
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDispenseDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2EC4F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Dispense Food Now'),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   SMALL WIDGETS
============================================================ */

class _ConnectionBadge extends StatelessWidget {
  final bool online;

  const _ConnectionBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: online ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'CONNECTED' : 'DISCONNECTED',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatusItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2EC4F1)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/* ============================================================
   DISPENSE
============================================================ */

void _showDispenseDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Feed Level',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _levelButton(context, 'sedikit', Colors.green),
          _levelButton(context, 'sedang', Colors.orange),
          _levelButton(context, 'banyak', Colors.red),
        ],
      ),
    ),
  );
}

Widget _levelButton(BuildContext context, String level, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          final feederId = userDoc.data()?['feederId'];
          if (feederId == null) return;

          await FirebaseFirestore.instance
              .collection('feeders')
              .doc(feederId)
              .collection('commands')
              .add({
            'type': 'dispense',
            'level': level,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(level.toUpperCase()),
      ),
    ),
  );
}

/* ============================================================
   BOTTOM NAV
============================================================ */

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.home, 0),
          _navIcon(Icons.calendar_month, 1),
          const SizedBox(width: 40),
          _navIcon(Icons.smart_toy, 2),
          _navIcon(Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: currentIndex == index
            ? const Color(0xFF2EC4F1)
            : Colors.grey,
      ),
      onPressed: () => onTap(index),
    );
  }
}
