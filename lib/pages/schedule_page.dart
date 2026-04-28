import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String? feederId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeederId();
  }

  Future<void> _loadFeederId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    feederId = userDoc.data()?['feederId'];
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (feederId == null || feederId!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.link_off, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Feeder belum di-pair',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Silakan pairing feeder terlebih dahulu',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return _ScheduleUI(feederId: feederId!);
  }
}

/* ========================================================= */

class _ScheduleUI extends StatelessWidget {
  final String feederId;
  const _ScheduleUI({required this.feederId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2EC4F1),
        child: const Icon(Icons.add),
        onPressed: () => _openAddSchedule(context, feederId),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Icon(Icons.schedule,
                      color: Color(0xFF2EC4F1), size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feeding Schedule',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage automatic feeding time',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feeders')
                    .doc(feederId)
                    .collection('schedules')
                    .orderBy('timeInMinutes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No feeding schedule yet'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final time =
                          '${data['hour'].toString().padLeft(2, '0')}:${data['minute'].toString().padLeft(2, '0')}';

                      return Dismissible(
                        key: Key(docs[index].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Schedule'),
                              content: const Text(
                                  'Are you sure you want to delete this schedule?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) =>
                            docs[index].reference.delete(),
                        child: _ScheduleCard(
                          time: time,
                          days: List<int>.from(data['days']),
                          level: data['level'],
                          enabled: data['enabled'],
                          onToggle: (v) =>
                              docs[index].reference.update({'enabled': v}),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================================================= */

class _ScheduleCard extends StatelessWidget {
  final String time;
  final List<int> days;
  final String level;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _ScheduleCard({
    required this.time,
    required this.days,
    required this.level,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_daysText(days),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _levelColor(level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(level.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          )
        ],
      ),
    );
  }
}

/* ========================================================= */

void _openAddSchedule(BuildContext context, String feederId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddScheduleSheet(feederId: feederId),
  );
}

class _AddScheduleSheet extends StatefulWidget {
  final String feederId;
  const _AddScheduleSheet({required this.feederId});

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String? _level;
  final Set<int> _days = {};

  Future<void> _save() async {
    final t = _time.hour * 60 + _time.minute;

    await FirebaseFirestore.instance
        .collection('feeders')
        .doc(widget.feederId)
        .collection('schedules')
        .add({
      'hour': _time.hour,
      'minute': _time.minute,
      'timeInMinutes': t,
      'days': _days.toList(),
      'level': _level,
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: Text('Add Feeding Schedule',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Time'),
              trailing: Text(_time.format(context)),
              onTap: () async {
                final p = await showTimePicker(
                    context: context, initialTime: _time);
                if (p != null) setState(() => _time = p);
              },
            ),

            const Text('Days'),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                return ChoiceChip(
                  label: Text(labels[i]),
                  selected: _days.contains(i),
                  onSelected: (_) => setState(() {
                    _days.contains(i) ? _days.remove(i) : _days.add(i);
                  }),
                );
              }),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _levelBtn('sedikit', Colors.green),
                const SizedBox(width: 8),
                _levelBtn('sedang', Colors.orange),
                const SizedBox(width: 8),
                _levelBtn('banyak', Colors.red),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _level != null && _days.isNotEmpty ? _save : null,
                child: const Text('Save Schedule'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _levelBtn(String l, Color c) {
    final s = _level == l;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _level = l),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: s ? c : c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: Text(l.toUpperCase(),
                  style: TextStyle(
                      color: s ? Colors.white : c,
                      fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}

/* ========================================================= */

String _daysText(List<int> days) {
  const map = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  days.sort();
  return days.map((d) => map[d]).join(', ');
}

Color _levelColor(String level) {
  switch (level) {
    case 'sedikit':
      return Colors.green;
    case 'sedang':
      return Colors.orange;
    case 'banyak':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
