// booking_list_widget.dart
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../localization/language_constants.dart';
import '../screens/request_screen.dart';

class BookingList extends StatefulWidget {
  final String status;
  final Future<void> Function(BuildContext, Map)? showDialogFunction;
  final Future<void> Function(BuildContext, Map)? showDialogCoffeFunction;

  BookingList({
    required this.status,
    this.showDialogFunction,
    this.showDialogCoffeFunction,
  });

  @override
  _BookingListState createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _df = DateFormat('yyyy-MM-dd');

  void _updateSearchQuery(String query) => setState(() => _searchQuery = query);
  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    _updateSearchQuery("");
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget _buildShimmerItem() => Padding(
        padding: const EdgeInsets.all(10.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    final noRequestsText = () {
      switch (widget.status) {
        case "1":
          return getTranslated(context, "No new booking requests");
        case "2":
          return getTranslated(context, "No accepted booking requests");
        case "3":
          return getTranslated(context, "No rejected booking requests");
        default:
          return getTranslated(context, "No recent booking requests");
      }
    }();

    final baseRef = FirebaseDatabase.instance.ref("App/Booking/Book");
    final query = widget.status == "recent"
        ? baseRef.orderByChild("Status").startAt("2").endAt("3").limitToLast(10)
        : baseRef.orderByChild("Status").equalTo(widget.status);
    final now = DateTime.now();

    return Column(
      children: [
        10.kH,

        // Date-range pickers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "FromDate"),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate != null ? _df.format(_startDate!) : "-",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: getTranslated(context, "ToDate"),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate != null ? _df.format(_endDate!) : "-",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: getTranslated(
                  context, "Search by Booking ID or Phone Number"),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _updateSearchQuery,
          ),
        ),

        // Booking list
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: query.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dbSnap = snapshot.data?.snapshot;
              if (dbSnap == null || dbSnap.value == null) {
                return Center(
                  child: Text(noRequestsText,
                      style: const TextStyle(fontSize: 16)),
                );
              }

              // 1) collect all children
              final all = dbSnap.children.toList();

              // 2) apply all filters in one go
              final filtered = all.where((snap) {
                final v = Map<String, dynamic>.from(
                    snap.value as Map<dynamic, dynamic>);

                // Owner filter
                if (v['IDOwner']?.toString() != currentUid) return false;

                // Text search filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final id = v['IDBook'].toString().toLowerCase();
                  final phone = v['PhoneNumber'].toString().toLowerCase();
                  if (!(id.contains(q) || phone.contains(q))) return false;
                }

                // Date-range filter
                if ((_startDate != null || _endDate != null) &&
                    v['StartDate'] != null) {
                  final dt = DateTime.tryParse(v['StartDate']);
                  if (dt == null) return false;

                  if (_startDate != null && _endDate == null) {
                    if (!(dt.year == _startDate!.year &&
                        dt.month == _startDate!.month &&
                        dt.day == _startDate!.day)) return false;
                  } else if (_startDate == null && _endDate != null) {
                    if (!(dt.year == _endDate!.year &&
                        dt.month == _endDate!.month &&
                        dt.day == _endDate!.day)) return false;
                  } else {
                    if (_startDate != null && dt.isBefore(_startDate!))
                      return false;
                    if (_endDate != null && dt.isAfter(_endDate!)) return false;
                  }
                }

                // Time-based “accepted/rejected” filter
                if ((widget.status == "2" || widget.status == "3") &&
                    v['StartDate'] != null) {
                  DateTime? sd = DateTime.tryParse(v['StartDate']);
                  final c = v['Clock']?.toString() ?? "";
                  if (sd != null && c.contains(':')) {
                    final p = c.split(':');
                    sd = DateTime(sd.year, sd.month, sd.day, int.parse(p[0]),
                        int.parse(p[1]));
                    if (widget.status == "2")
                      sd = sd.add(const Duration(hours: 24));
                    if (now.isAfter(sd)) return false;
                  }
                }

                return true;
              }).toList();

              // 3) if nothing remains → “no requests”
              if (filtered.isEmpty) {
                return Center(
                  child: Text(noRequestsText,
                      style: const TextStyle(fontSize: 16)),
                );
              }

              // 4) otherwise render exactly those bookings
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final snap = filtered[i];
                  final v = Map<String, dynamic>.from(
                      snap.value as Map<dynamic, dynamic>);
                  v['Key'] = snap.key;
                  return _buildBookingCard(ctx, v, now);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(
      BuildContext context, Map<String, dynamic> v, DateTime now) {
    // Locale-aware estate name
    final locale = Localizations.localeOf(context).languageCode;
    final estateName = locale == 'ar'
        ? (v['NameAr'] ?? 'غير معروف')
        : (v['NameEn'] ?? 'Unknown');

    // Build rejection display
    String rejectionDisplay = '';
    if (v['Status'] == '3' && v['RejectionReason'] != null) {
      final rr = v['RejectionReason'];
      if (rr is Map) {
        final rv = rr['value']?.toString() ?? '';
        final det = rr['details']?.toString() ?? '';
        rejectionDisplay = _getLocalizedRejectionReason(context, rv);
        if (det.isNotEmpty) rejectionDisplay += ' > $det';
      } else {
        rejectionDisplay = _getLocalizedRejectionReason(context, rr.toString());
      }
    }

    void _handleTap() {
      if (v['Status'] == '1') {
        if (v['EndDate']?.toString().isNotEmpty == true) {
          widget.showDialogFunction?.call(context, v);
        } else {
          widget.showDialogCoffeFunction?.call(context, v);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header row: ID + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${getTranslated(context, "Booking ID")}: #${v['IDBook']}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _buildStatusChip(context, v['Status']),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // FromDate / ToDate
                Row(
                  children: [
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.calendar_today,
                        label: getTranslated(context, "FromDate") ?? '',
                        value: v['StartDate']?.toString() ?? '',
                      ),
                    ),
                    if (v['EndDate']?.toString().isNotEmpty == true)
                      const SizedBox(width: 10),
                    if (v['EndDate']?.toString().isNotEmpty == true)
                      Expanded(
                        child: _buildIconText(
                          context: context,
                          icon: Icons.calendar_today,
                          label: getTranslated(context, "ToDate") ?? '',
                          value: v['EndDate'].toString(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Time & Customer Name
                Row(
                  children: [
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.timer,
                        label: getTranslated(context, "Time") ?? '',
                        value: v['Clock'].toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.person,
                        label: getTranslated(context, "Customer Name") ?? '',
                        value: v['NameUser'] ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Phone & Rate
                Row(
                  children: [
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.phone_android_outlined,
                        label: getTranslated(context, "Phone Number") ?? '',
                        value: v['PhoneNumber'] ?? '',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.star,
                        label: getTranslated(context, "Rate") ?? '',
                        value: v['Rating'] != null
                            ? double.parse(v['Rating'].toString())
                                .toStringAsFixed(1)
                            : '0.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Smoker & Allergies
                Row(
                  children: [
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.smoking_rooms,
                        label: getTranslated(context, "Smoker") ?? '',
                        value: v['Smoker'] ?? 'No',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.notes,
                        label: getTranslated(context, "Allergies") ?? '',
                        value: v['Allergies'] ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Estate Name
                Row(
                  children: [
                    Expanded(
                      child: _buildIconText(
                        context: context,
                        icon: Icons.business,
                        label: getTranslated(context, "Estate Name") ?? '',
                        value: estateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rejection reason
                if (v['Status'] == '3' && rejectionDisplay.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildIconText(
                      context: context,
                      icon: Icons.info_outline,
                      label: getTranslated(context, "Rejection Reason"),
                      value: rejectionDisplay,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedRejectionReason(BuildContext context, String reason) {
    final lang = Localizations.localeOf(context).languageCode;
    const map = <String, Map<String, String>>{
      'en': {
        'Incorrect booking details': 'Incorrect booking details',
        'تفاصيل الحجز غير صحيحة': 'Incorrect booking details',
        'Unavailability of required facilities':
            'Unavailability of required facilities',
        'عدم توفر المرافق المطلوبة': 'Unavailability of required facilities',
        'Booking is full': 'Booking is full',
        'الحجز ممتلئ': 'Booking is full',
        'Other': 'Other',
        'أخرى': 'Other',
      },
      'ar': {
        'Incorrect booking details': 'تفاصيل الحجز غير صحيحة',
        'تفاصيل الحجز غير صحيحة': 'تفاصيل الحجز غير صحيحة',
        'Unavailability of required facilities': 'عدم توفر المرافق المطلوبة',
        'عدم توفر المرافق المطلوبة': 'عدم توفر المرافق المطلوبة',
        'Booking is full': 'الحجز ممتلئ',
        'الحجز ممتلئ': 'الحجز ممتلئ',
        'Other': 'أخرى',
        'أخرى': 'أخرى',
      },
    };
    return map[lang]?[reason] ?? reason;
  }

  Widget _buildIconText({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String bookingStatus) {
    late Color bg;
    late String label;
    switch (bookingStatus) {
      case '1':
        bg = Colors.blueGrey;
        label = getTranslated(context, 'Processing');
        break;
      case '2':
        bg = Colors.green;
        label = getTranslated(context, 'Accepted');
        break;
      case '3':
        bg = Colors.red;
        label = getTranslated(context, 'Rejected');
        break;
      default:
        bg = Colors.grey;
        label = getTranslated(context, 'Unknown');
    }
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: bg,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
