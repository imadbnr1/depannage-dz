import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_feedback.dart';
import '../../../core/services/csv_exporter.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  _AnalyticsPreset _preset = _AnalyticsPreset.last30Days;
  DateTime? _customStart;
  DateTime? _customEnd;

  _DateWindow get _activeWindow {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (_preset) {
      case _AnalyticsPreset.today:
        return _DateWindow(
          label: 'Aujourd hui',
          start: todayStart,
          end: now,
        );
      case _AnalyticsPreset.yesterday:
        final start = todayStart.subtract(const Duration(days: 1));
        return _DateWindow(
          label: 'Hier',
          start: start,
          end: todayStart.subtract(const Duration(milliseconds: 1)),
        );
      case _AnalyticsPreset.last7Days:
        return _DateWindow(
          label: '7 derniers jours',
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case _AnalyticsPreset.last30Days:
        return _DateWindow(
          label: '30 derniers jours',
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case _AnalyticsPreset.all:
        return const _DateWindow(
          label: 'Toutes les donnees',
          start: null,
          end: null,
        );
      case _AnalyticsPreset.custom:
        return _DateWindow(
          label: 'Periode personnalisee',
          start: _customStart,
          end: _customEnd,
        );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  DateTime? _firstDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _toDate(data[key]);
      if (value != null) return value;
    }
    return null;
  }

  DateTime? _analyticsDate(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    if (status == 'completed') {
      return _firstDate(data, const [
        'completedAtIso',
        'completedAt',
        'statusChangedAtIso',
        'updatedAtIso',
        'updatedAt',
        'createdAtIso',
        'createdAt',
      ]);
    }
    if (status == 'cancelled') {
      return _firstDate(data, const [
        'cancelledAtIso',
        'cancelledAt',
        'statusChangedAtIso',
        'updatedAtIso',
        'updatedAt',
        'createdAtIso',
        'createdAt',
      ]);
    }
    return _firstDate(data, const [
      'statusChangedAtIso',
      'updatedAtIso',
      'updatedAt',
      'createdAtIso',
      'createdAt',
    ]);
  }

  String _formatMoney(double value) => '${value.toStringAsFixed(0)} DA';

  String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _safeFilePart(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _csvCell(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  String _buildCsvReport({
    required _DateWindow window,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> completedDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activeDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> cancelledDocs,
    required double totalRevenue,
    required double totalCommission,
    required double averageTicket,
    required double completionRate,
  }) {
    final rows = <List<Object?>>[
      ['Depaniny admin analytics report'],
      ['Generated at', _formatDateTime(DateTime.now())],
      ['Period', window.rangeLabel(_formatDateTime)],
      const [],
      ['Metric', 'Value'],
      ['Total requests', filteredDocs.length],
      ['Active requests', activeDocs.length],
      ['Completed requests', completedDocs.length],
      ['Cancelled requests', cancelledDocs.length],
      ['Revenue DA', totalRevenue.toStringAsFixed(0)],
      ['Platform commission DA', totalCommission.toStringAsFixed(0)],
      ['Average ticket DA', averageTicket.toStringAsFixed(0)],
      ['Completion rate %', completionRate.toStringAsFixed(1)],
      const [],
      [
        'Request ID',
        'Status',
        'Date',
        'Customer',
        'Provider',
        'Pickup',
        'Destination',
        'Price DA',
        'Service',
      ],
    ];

    final sortedDocs = [...filteredDocs]..sort((a, b) {
        final aDate =
            _analyticsDate(a.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            _analyticsDate(b.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    for (final doc in sortedDocs) {
      final data = doc.data();
      rows.add([
        doc.id,
        data['status'],
        _formatDateTime(_analyticsDate(data)),
        data['customerName'],
        data['providerName'],
        data['pickup'],
        data['destination'],
        _toDouble(data['estimatedPrice']).toStringAsFixed(0),
        data['serviceType'],
      ]);
    }

    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  Future<void> _exportReport({
    required _DateWindow window,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> completedDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activeDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> cancelledDocs,
    required double totalRevenue,
    required double totalCommission,
    required double averageTicket,
    required double completionRate,
  }) async {
    final csv = _buildCsvReport(
      window: window,
      filteredDocs: filteredDocs,
      completedDocs: completedDocs,
      activeDocs: activeDocs,
      cancelledDocs: cancelledDocs,
      totalRevenue: totalRevenue,
      totalCommission: totalCommission,
      averageTicket: averageTicket,
      completionRate: completionRate,
    );
    final stamp = DateTime.now().toIso8601String().split('.').first;
    final fileName =
        'depaniny_analytics_${_safeFilePart(window.label)}_${_safeFilePart(stamp)}.csv';

    await exportCsvFile(fileName: fileName, content: csv);
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      kIsWeb
          ? 'Rapport CSV telecharge.'
          : 'Rapport CSV copie dans le presse-papiers.',
    );
  }

  Future<void> _pickCustomBoundary({required bool start}) async {
    final now = DateTime.now();
    final current = start ? _customStart : _customEnd;
    final fallback = start ? DateTime(now.year, now.month, now.day) : now;
    final initial = current ?? fallback;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: start ? 'Date debut' : 'Date fin',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: start ? 'Heure debut' : 'Heure fin',
    );
    if (!mounted) return;

    final pickedTime = time ??
        (start
            ? const TimeOfDay(hour: 0, minute: 0)
            : const TimeOfDay(hour: 23, minute: 59));
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      pickedTime.hour,
      pickedTime.minute,
      start ? 0 : 59,
    );

    setState(() {
      _preset = _AnalyticsPreset.custom;
      if (start) {
        _customStart = picked;
        if (_customEnd != null && _customEnd!.isBefore(picked)) {
          _customEnd = picked.add(const Duration(hours: 1));
        }
      } else {
        _customEnd = picked;
        if (_customStart != null && _customStart!.isAfter(picked)) {
          _customStart = picked.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestsStream =
        FirebaseFirestore.instance.collection('requests').snapshots();

    final pricingStream = FirebaseFirestore.instance
        .collection('app_config')
        .doc('pricing')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: requestsStream,
      builder: (context, requestsSnapshot) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: pricingStream,
          builder: (context, pricingSnapshot) {
            if (requestsSnapshot.connectionState == ConnectionState.waiting ||
                pricingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final requestDocs = requestsSnapshot.data?.docs ?? [];
            final pricingData =
                pricingSnapshot.data?.data() ?? <String, dynamic>{};
            final window = _activeWindow;

            final filteredDocs = requestDocs.where((doc) {
              return window.contains(_analyticsDate(doc.data()));
            }).toList();

            final commissionPercent = _toDouble(
              pricingData['commissionPercent'],
            ).clamp(0, 100).toDouble();

            final totalRequests = filteredDocs.length;
            final completedDocs = filteredDocs
                .where((d) => (d.data()['status'] ?? '') == 'completed')
                .toList();
            final cancelledDocs = filteredDocs
                .where((d) => (d.data()['status'] ?? '') == 'cancelled')
                .toList();
            final activeDocs = filteredDocs.where((d) {
              final s = (d.data()['status'] ?? '').toString();
              return s == 'accepted' ||
                  s == 'onTheWay' ||
                  s == 'arrived' ||
                  s == 'inService';
            }).toList();

            final searchingDocs = filteredDocs
                .where((d) => (d.data()['status'] ?? '') == 'searching')
                .toList();

            double totalRevenue = 0;
            for (final doc in completedDocs) {
              totalRevenue += _toDouble(doc.data()['estimatedPrice']);
            }

            final totalCommission = totalRevenue * (commissionPercent / 100.0);
            final averageTicket = completedDocs.isEmpty
                ? 0.0
                : totalRevenue / completedDocs.length;
            final completionRate = filteredDocs.isEmpty
                ? 0.0
                : (completedDocs.length / filteredDocs.length) * 100;

            final recentCompleted = [...completedDocs];
            recentCompleted.sort((a, b) {
              final aDate = _analyticsDate(a.data()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = _analyticsDate(b.data()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AnalyticsFilterPanel(
                  selectedPreset: _preset,
                  windowLabel: window.rangeLabel(_formatDateTime),
                  startLabel: _formatDateTime(_customStart),
                  endLabel: _formatDateTime(_customEnd),
                  onPresetChanged: (preset) {
                    setState(() => _preset = preset);
                  },
                  onPickStart: () => _pickCustomBoundary(start: true),
                  onPickEnd: () => _pickCustomBoundary(start: false),
                  onClearCustom: () {
                    setState(() {
                      _preset = _AnalyticsPreset.last30Days;
                      _customStart = null;
                      _customEnd = null;
                    });
                  },
                  onExport: () => _exportReport(
                    window: window,
                    filteredDocs: filteredDocs,
                    completedDocs: completedDocs,
                    activeDocs: activeDocs,
                    cancelledDocs: cancelledDocs,
                    totalRevenue: totalRevenue,
                    totalCommission: totalCommission,
                    averageTicket: averageTicket,
                    completionRate: completionRate,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 860 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: columns == 4 ? 1.22 : 1.28,
                      children: [
                        _StatCard(
                          title: 'Demandes filtrees',
                          value: '$totalRequests',
                          icon: Icons.receipt_long_outlined,
                        ),
                        _StatCard(
                          title: 'Actives',
                          value: '${activeDocs.length}',
                          icon: Icons.local_shipping_outlined,
                        ),
                        _StatCard(
                          title: 'Terminees',
                          value: '${completedDocs.length}',
                          icon: Icons.check_circle_outline,
                        ),
                        _StatCard(
                          title: 'Annulees',
                          value: '${cancelledDocs.length}',
                          icon: Icons.cancel_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: columns == 3 ? 2.25 : 3.1,
                      children: [
                        _MoneyCard(
                          title: 'Chiffre filtre',
                          value: _formatMoney(totalRevenue),
                          subtitle: 'Missions terminees dans la periode',
                          icon: Icons.payments_outlined,
                        ),
                        _MoneyCard(
                          title: 'Commission plateforme',
                          value: _formatMoney(totalCommission),
                          subtitle: 'Basee sur $commissionPercent %',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _MoneyCard(
                          title: 'Panier moyen',
                          value: _formatMoney(averageTicket),
                          subtitle: 'Moyenne par mission terminee',
                          icon: Icons.analytics_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _OperationalStrip(
                  searching: searchingDocs.length,
                  completionRate: completionRate,
                  commissionPercent: commissionPercent,
                  rangeLabel: window.label,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dernieres missions terminees',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      '${recentCompleted.length} resultats',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (recentCompleted.isEmpty)
                  const _EmptyCard(
                    text: 'Aucune mission terminee dans cette periode',
                  ),
                ...recentCompleted.take(12).map((doc) {
                  final data = doc.data();
                  final customerName =
                      (data['customerName'] ?? 'Client').toString();
                  final providerName =
                      (data['providerName'] ?? '--').toString();
                  final destination = (data['destination'] ?? '--').toString();
                  final price = _toDouble(data['estimatedPrice']);
                  final when = _analyticsDate(data);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(when),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(title: 'Provider', value: providerName),
                        _InfoRow(title: 'Destination', value: destination),
                        _InfoRow(
                          title: 'Montant',
                          value: _formatMoney(price),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

enum _AnalyticsPreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  all,
  custom,
}

extension _AnalyticsPresetLabel on _AnalyticsPreset {
  String get label {
    switch (this) {
      case _AnalyticsPreset.today:
        return 'Aujourd hui';
      case _AnalyticsPreset.yesterday:
        return 'Hier';
      case _AnalyticsPreset.last7Days:
        return '7 jours';
      case _AnalyticsPreset.last30Days:
        return '30 jours';
      case _AnalyticsPreset.all:
        return 'Tout';
      case _AnalyticsPreset.custom:
        return 'Custom';
    }
  }
}

class _DateWindow {
  const _DateWindow({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime? value) {
    if (start == null && end == null) return true;
    if (value == null) return false;
    if (start != null && value.isBefore(start!)) return false;
    if (end != null && value.isAfter(end!)) return false;
    return true;
  }

  String rangeLabel(String Function(DateTime?) formatter) {
    if (start == null && end == null) return 'Toutes les dates';
    return '${formatter(start)} -> ${formatter(end)}';
  }
}

class _AnalyticsFilterPanel extends StatelessWidget {
  const _AnalyticsFilterPanel({
    required this.selectedPreset,
    required this.windowLabel,
    required this.startLabel,
    required this.endLabel,
    required this.onPresetChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearCustom,
    required this.onExport,
  });

  final _AnalyticsPreset selectedPreset;
  final String windowLabel;
  final String startLabel;
  final String endLabel;
  final ValueChanged<_AnalyticsPreset> onPresetChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearCustom;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Color(0xFFE89A1E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtres analytics',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      windowLabel,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: onClearCustom,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.download_outlined),
                label: const Text('CSV'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _AnalyticsPreset.values.map((preset) {
              return ChoiceChip(
                label: Text(preset.label),
                selected: selectedPreset == preset,
                onSelected: (_) => onPresetChanged(preset),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final start = _DateButton(
                label: 'Debut',
                value: startLabel,
                icon: Icons.event_available_outlined,
                onTap: onPickStart,
              );
              final end = _DateButton(
                label: 'Fin',
                value: endLabel,
                icon: Icons.event_busy_outlined,
                onTap: onPickEnd,
              );

              if (compact) {
                return Column(
                  children: [
                    start,
                    const SizedBox(height: 10),
                    end,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: start),
                  const SizedBox(width: 10),
                  Expanded(child: end),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_calendar_outlined,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationalStrip extends StatelessWidget {
  const _OperationalStrip({
    required this.searching,
    required this.completionRate,
    required this.commissionPercent,
    required this.rangeLabel,
  });

  final int searching;
  final double completionRate;
  final double commissionPercent;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MiniInsight(
            label: 'Periode',
            value: rangeLabel,
            icon: Icons.schedule_outlined,
          ),
          _MiniInsight(
            label: 'En recherche',
            value: '$searching',
            icon: Icons.radar_outlined,
          ),
          _MiniInsight(
            label: 'Taux completion',
            value: '${completionRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up_rounded,
          ),
          _MiniInsight(
            label: 'Commission',
            value: '${commissionPercent.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF8FAFC),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
