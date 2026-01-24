import 'package:bullxchange/features/stock_market/screens/order_details_page.dart';
import 'package:bullxchange/models/transaction_model.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FnoTransactionsPage extends StatefulWidget {
  const FnoTransactionsPage({super.key});

  @override
  State<FnoTransactionsPage> createState() => _FnoTransactionsPageState();
}

class _FnoTransactionsPageState extends State<FnoTransactionsPage> {
  final UserService _userService = UserService();
  late Stream<List<TransactionModel>> _transactionStream;
  String _currentUid = "";

  @override
  void initState() {
    super.initState();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    _currentUid = firebaseUser?.uid ?? "";

    if (_currentUid.isNotEmpty) {
      _transactionStream = _userService.streamRecentTransactions(_currentUid);
    } else {
      _transactionStream = Stream.value([]);
    }
  }

  String _getFnoDisplayName(TransactionModel txn) {
    if (txn.optionType != null && txn.strikePrice != null) {
      return "${txn.stockSymbol} ${txn.strikePrice!.toStringAsFixed(0)} ${txn.optionType}";
    }
    return txn.stockSymbol;
  }

  bool _isFno(TransactionModel txn) {
    return txn.optionType != null || txn.lotSize != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final Color subTextColor = const Color(0xFF8E8E93);

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    const Color kGreen = Color(0xFF34C759);
    const Color kRed = Color(0xFFFF3B30);

    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(textColor, subTextColor);
        }

        // 1. Filter F&O
        final allTransactions = snapshot.data!;
        final fnoTransactionsPage = allTransactions.where(_isFno).toList();

        if (fnoTransactionsPage.isEmpty) {
          return _buildEmptyState(textColor, subTextColor);
        }

        // 2. Group by Date
        final groupedTransactions = _groupTransactionsByDate(
          fnoTransactionsPage,
        );

        return ListView.builder(
          // Important: Physics allows scrolling inside the tab
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 10),
          itemCount: groupedTransactions.keys.length,
          itemBuilder: (context, index) {
            String dateKey = groupedTransactions.keys.elementAt(index);
            List<TransactionModel> txns = groupedTransactions[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    dateKey.toUpperCase(),
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Transactions Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: txns.length,
                    separatorBuilder: (ctx, idx) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 60,
                      color: subTextColor.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (ctx, idx) {
                      return _buildTransactionItem(
                        txns[idx],
                        currency,
                        textColor,
                        subTextColor,
                        kGreen,
                        kRed,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ITEM WIDGET (WITH OVERFLOW FIX) ---
  Widget _buildTransactionItem(
    TransactionModel txn,
    NumberFormat currency,
    Color textColor,
    Color subTextColor,
    Color kGreen,
    Color kRed,
  ) {
    final bool isBuy = txn.transactionType == "BUY";
    final String timeStr = DateFormat('h:mm a').format(txn.transactionTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(
                transaction: txn,
                transactionId: txn.id ?? "Unknown ID",
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isBuy ? kGreen : kRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBuy
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isBuy ? kGreen : kRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // 2. Middle Details (Name & Subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getFnoDisplayName(txn),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (txn.orderStatus != 'EXECUTED') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              txn.orderStatus,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Subtitle (Rich Text to fix overflow)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isBuy ? "BUY" : "SELL",
                            style: TextStyle(
                              color: isBuy ? kGreen : kRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: " • ${txn.quantity} Qty",
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                          if (txn.lotSize != null)
                            TextSpan(
                              text: " (${txn.quantity ~/ txn.lotSize!} Lots)",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                              ),
                            ),
                          TextSpan(
                            text: " • $timeStr",
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Trailing (Amount & Price)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(txn.totalAmount),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Avg. ${currency.format(txn.price)}",
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: subTextColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Transactions Found",
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> list,
  ) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var txn in list) {
      final date = txn.transactionTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txnDate = DateTime(date.year, date.month, date.day);

      String key;
      if (txnDate == today) {
        key = "Today";
      } else if (txnDate == yesterday) {
        key = "Yesterday";
      } else {
        key = DateFormat('MMMM d, y').format(date);
      }

      if (grouped[key] == null) grouped[key] = [];
      grouped[key]!.add(txn);
    }
    return grouped;
  }
}
