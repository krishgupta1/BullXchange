import 'package:bullxchange/features/auth/screens/onboarding_page_1.1.dart';
import 'package:bullxchange/features/stock_market/screens/explore_page.dart';
import 'package:bullxchange/features/stock_market/screens/holdings_page.dart';
import 'package:bullxchange/features/stock_market/screens/order_page.dart';
import 'package:bullxchange/features/stock_market/screens/position_page.dart';
import 'package:bullxchange/features/stock_market/screens/watchlist_page.dart';
import 'package:bullxchange/features/stock_market/widgets/shimmer_animation.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_list_item.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Page State
  int _selectedActionIndex = 0;
  String? _userName;
  String? _uid;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✨ OPTIMIZATION: Lists are initialized empty to save memory.
  List<Instrument> _allStocks = [];
  List<Instrument> _filteredStocks = [];
  List<Instrument> _displayedStocks = [];

  bool _stocksInitialized = false; // Flag to check if _allStocks is populated
  bool _isLoadingMore = false;
  final int _batchSize = 50;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _uid = user.uid);
      }

      if (user != null &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        setState(() => _userName = user.displayName);
        return;
      }

      if (_uid != null) {
        final profile = await UserService().readUserProfile(_uid!);
        if (profile != null && profile.name.trim().isNotEmpty) {
          if (!mounted) return;
          setState(() => _userName = profile.name);
          return;
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  // ----------------------------------------------------
  // SEARCH LOGIC (Optimized for On-Demand)
  // ----------------------------------------------------

  // ✨ This now ONLY populates _allStocks. It's called just once.
  void _initializeStocks(InstrumentProvider provider) {
    if (_stocksInitialized || provider.allNSEStocks.isEmpty) return;

    _allStocks = provider.allNSEStocks.where((stock) {
      final baseSymbol = stock.symbol.replaceAll('-EQ', '');
      final lowerCaseName = stock.name.toLowerCase();
      if (baseSymbol.contains(RegExp(r'[0-9]'))) return false;
      const excludedKeywords = [
        'etf',
        'bees',
        'nifty',
        'gold',
        'bond',
        'debenture',
        'pref',
        'index',
      ];
      if (excludedKeywords.any((keyword) => lowerCaseName.contains(keyword))) {
        return false;
      }
      if (baseSymbol.length < 3 || baseSymbol.length > 12) return false;
      if (!RegExp(r'^[A-Z]+$').hasMatch(baseSymbol)) return false;
      return true;
    }).toList();

    _stocksInitialized = true;
  }

  void _onScroll() {
    // ✨ Only run scroll listener if we are actually searching
    if (!_isSearching) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _displayedStocks.length < _filteredStocks.length) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;
    if (mounted) setState(() => _isLoadingMore = true);

    final currentLength = _displayedStocks.length;
    final moreItems = _filteredStocks
        .skip(currentLength)
        .take(_batchSize)
        .toList();

    if (moreItems.isNotEmpty) {
      if (mounted) {
        setState(() {
          _displayedStocks.addAll(moreItems);
        });
      }
    }

    if (context.mounted) {
      final provider = Provider.of<InstrumentProvider>(context, listen: false);
      provider.fetchLiveDataFor(moreItems);
    }

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onSearchChanged() {
    _searchStocks(_searchController.text);
  }

  void _searchStocks(String query) {
    // ✨ 1. Initialize the master list ONCE, on the first search action.
    if (!_stocksInitialized) {
      final provider = Provider.of<InstrumentProvider>(context, listen: false);
      _initializeStocks(provider);
    }

    // ✨ 2. If query is empty, clear results and show nothing.
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredStocks = [];
          _displayedStocks.clear();
        });
      }
      return; // Stop here
    }

    // ✨ 3. Run search on the (now populated) _allStocks list
    final results = _allStocks.where((stock) {
      final symbol = stock.symbol.toLowerCase();
      final name = stock.name.toLowerCase();
      final searchQuery = query.toLowerCase();
      return symbol.contains(searchQuery) || name.contains(searchQuery);
    }).toList();

    if (mounted) {
      setState(() {
        _filteredStocks = results;
        _displayedStocks.clear();
      });
    }
    _loadMoreItems(); // Load first batch of results
  }

  void _cancelSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchController.clear();
    if (mounted) {
      setState(() {
        _isSearching = false;
        // ✨ Clear lists to free up memory
        _filteredStocks = [];
        _displayedStocks.clear();
      });
    }
  }

  // ----------------------------------------------------
  // BUILD METHOD
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamProvider<List<OrderModel>>.value(
      value: _uid != null
          ? UserService().streamOpenOrders(_uid!)
          : Stream.value([]),
      initialData: const [],
      child: Consumer<InstrumentProvider>(
        builder: (context, provider, child) {
          // ✨ REMOVED: No more eager initialization.

          // We check `allNSEStocks` as it's the dependency for search.
          // The Nifty/BankNifty data loads separately.
          if (provider.isLoading && provider.allNSEStocks.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 30),

                  if (!_isSearching) ...[
                    _buildIndexCards(provider.nifty50, provider.bankNifty),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    IndexedStack(
                      index: _selectedActionIndex,
                      children: [
                        ExplorePage(),
                        HoldingsPage(),
                        PositionPage(),
                        const OrderPage(),
                        const WatchlistPage(),
                      ],
                    ),
                  ] else ...[
                    MediaQuery.removePadding(
                      context: context,
                      removeLeft: true,
                      removeRight: true,
                      child: _buildSearchResultsList(context),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // WIDGET BUILDER METHODS
  // ----------------------------------------------------

  Widget _buildHeader() {
    if (_isSearching) {
      return _buildSearchBar();
    }

    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFEAE2FF),
          child: Icon(Icons.person, color: Color(0xFF7A4DFF), size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${_userName ?? 'User'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              'Welcome to BullXchange',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
          icon: const Icon(Icons.search),
        ),
        IconButton(
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingPage()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search company, stocks...",
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDB1B57)),
          onPressed: _cancelSearch,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => _searchController.clear(),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF908FEC), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF7A4DFF), width: 2),
        ),
      ),
    );
  }

  Widget _buildIndexCards(Instrument? nifty50, Instrument? bankNifty) {
    // ... (This method is unchanged)
    return Row(
      children: [
        Expanded(child: _buildIndexCard(instrument: nifty50)),
        const SizedBox(width: 16),
        Expanded(child: _buildIndexCard(instrument: bankNifty)),
      ],
    );
  }

  Widget _buildIndexCard({required Instrument? instrument}) {
    // ... (This method is unchanged)
    final name =
        instrument?.name.toUpperCase().replaceFirst("NIFTY ", "") ??
        "LOADING...";
    final value = instrument?.liveData["ltp"]?.toString() ?? "--";
    final netChange = instrument?.liveData["netChange"]?.toString() ?? "0";
    final percentChange =
        instrument?.liveData["percentChange"]?.toString() ?? "0";
    final double changeValue = num.tryParse(netChange)?.toDouble() ?? 0.0;
    final changeColor = changeValue >= 0 ? Colors.green : Colors.red;
    final changeText = "$netChange ($percentChange%)";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value != "--" ? "₹$value" : value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // ... (This method is unchanged)
    final buttonLabels = [
      "Explore",
      "Holdings",
      "Position",
      "Orders",
      "Watchlist",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(buttonLabels.length, (index) {
          return _buildActionButton(buttonLabels[index], index);
        }),
      ),
    );
  }

  Widget _buildActionButton(String text, int index) {
    // ... (This method is unchanged)
    bool isSelected = _selectedActionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActionIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDB1B57) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // SEARCH RESULT WIDGETS (Ported from ViewAllPage)
  // ----------------------------------------------------

  Widget _buildSearchResultsList(BuildContext context) {
    // ✨ 1. If the query is empty, show a prompt
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("Start typing to search for stocks."),
        ),
      );
    }

    // ✨ 2. If loading first batch of results, show shimmer
    if (_isLoadingMore && _displayedStocks.isEmpty) {
      return _buildShimmerLoadingList();
    }

    // ✨ 3. If query is not empty, but results are
    if (_filteredStocks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("No stocks found."),
        ),
      );
    }

    // ✨ 4. Display results
    return Column(
      children: [
        ...List.generate(_displayedStocks.length, (index) {
          final instrument = _displayedStocks[index];
          return StockListItem(instrument: instrument);
        }),
        if (_isLoadingMore) _buildLoadMoreShimmer(),
      ],
    );
  }
  // ----------------------------------------------------
  // SHIMMER HELPER WIDGETS
  // ----------------------------------------------------

  Widget _buildShimmerLoadingList() {
    // ... (This method is unchanged)
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(10, (index) => const StockListItemShimmer()),
      ),
    );
  }

  Widget _buildLoadMoreShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          // ✨ WAS: _buildShimmerStockItem(),
          const StockListItemShimmer(), // ✨ NOW
          const StockListItemShimmer(),
        ],
      ),
    );
  }
}
