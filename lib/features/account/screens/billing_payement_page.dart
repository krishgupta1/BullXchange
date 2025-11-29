import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- Local Model mapped to your 'fund_requests' collection ---
class FundRequestModel {
  final String id;
  final double amount;
  final String utrNumber;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime timestamp;

  FundRequestModel({
    required this.id,
    required this.amount,
    required this.utrNumber,
    required this.status,
    required this.timestamp,
  });

  factory FundRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime date = DateTime.now();
    if (data['timestamp'] != null) {
      date = (data['timestamp'] as Timestamp).toDate();
    }

    return FundRequestModel(
      id: doc.id,
      amount: (data['amount_rs'] as num?)?.toDouble() ?? 0.0,
      utrNumber: data['utr_number'] ?? 'N/A',
      status: data['status']?.toString().toLowerCase() ?? 'pending',
      timestamp: date,
    );
  }
}

class FundsHistoryPage extends StatelessWidget {
  const FundsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    if (uid == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: const Text("Funds History"),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: const Center(child: Text("Please log in.")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          "Wallet History",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Streaming data without ordering to avoid index errors
        stream: FirebaseFirestore.instance
            .collection('fund_requests')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Unable to load history",
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: _EmptyFundsState());
          }

          final requests = snapshot.data!.docs
              .map((doc) => FundRequestModel.fromFirestore(doc))
              .toList();

          // Client-side sorting (Newest first)
          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildFundRequestCard(
                context,
                requests[index],
                theme,
                colorScheme,
                currencyFormatter,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFundRequestCard(
    BuildContext context,
    FundRequestModel req,
    ThemeData theme,
    ColorScheme colorScheme,
    NumberFormat formatter,
  ) {
    // Status Logic
    Color statusColor;
    Color statusBg;
    String label;
    IconData iconData;

    switch (req.status) {
      case 'approved':
        statusColor = const Color(0xFF1EAB58); // Success Green
        statusBg = const Color(0xFF1EAB58).withOpacity(0.1);
        label = "Approved";
        iconData = Icons.arrow_downward_rounded;
        break;
      case 'rejected':
        statusColor = colorScheme.error;
        statusBg = colorScheme.error.withOpacity(0.1);
        label = "Rejected";
        iconData = Icons.close_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusBg = Colors.orange.withOpacity(0.1);
        label = "Pending";
        iconData = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Circle
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  iconData,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Funds",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(req.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                "+${formatter.format(req.amount)}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: req.status == 'rejected'
                      ? theme.disabledColor
                      : colorScheme.onSurface,
                  decoration: req.status == 'rejected'
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 12),
          // Footer: Status and UTR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // UTR Copy
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: req.utrNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("UTR copied to clipboard"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "UTR: ${req.utrNumber}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                        fontFamily: 'monospace', // Makes it look like a code
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: theme.disabledColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyFundsState extends StatelessWidget {
  const _EmptyFundsState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "No Transactions Found",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your fund requests will appear here.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
        ),
      ],
    );
  }
}



